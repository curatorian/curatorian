defmodule Curatorian.EventPayments do
  @moduledoc """
  Client for Atrium's internal event-payment API.

  The payment pipeline (charges, webhooks, revenue) lives in Atrium —
  see `atrium/lib/atrium/payment_gateway/ADAPTER_TEMPLATE.md`. This module is
  the thin checkout-side bridge: it asks Atrium to start (or resume) a charge
  for a registration and returns the gateway `redirect_url` the user should
  be sent to.

  Configuration:

      config :curatorian, :atrium_url   # already configured
      INTERNAL_API_KEY                  # env var, identical in both apps

  When `INTERNAL_API_KEY` is unset, or Atrium's gateway is unavailable, calls
  return `{:error, :unavailable}` and the checkout UI falls back to the
  offline-payment message — the flow never breaks.
  """

  require Logger

  @atrium_path "/api/internal/event-payments"
  @profiles_path "/api/internal/profiles"
  @timeout 10_000

  @doc """
  Starts (or resumes) a gateway charge for a registration.

  Returns:

    * `{:ok, %{redirect_url: url, order_id: id, amount_idr: n, status: "pending"}}`
    * `{:error, :not_configured}` — `INTERNAL_API_KEY` missing
    * `{:error, :unavailable}` — Atrium unreachable, gateway down, or a
      non-2xx response from the internal API
  """
  def start_payment(event_id, registration_id, user_id) do
    api_key = System.get_env("INTERNAL_API_KEY")

    if is_binary(api_key) and api_key != "" do
      do_start_payment(api_key, event_id, registration_id, user_id)
    else
      {:error, :not_configured}
    end
  end

  defp do_start_payment(api_key, event_id, registration_id, user_id) do
    base_url = Application.get_env(:curatorian, :atrium_url, "http://localhost:4001")
    url = String.trim_trailing(base_url, "/") <> @atrium_path

    request =
      Finch.build(
        :post,
        url,
        [
          {"x-internal-key", api_key},
          {"content-type", "application/json"},
          {"accept", "application/json"}
        ],
        Jason.encode!(%{
          event_id: event_id,
          registration_id: registration_id,
          voile_user_id: user_id
        })
      )

    case Finch.request(request, Curatorian.Finch, receive_timeout: @timeout) do
      {:ok, %{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"redirect_url" => redirect_url} = payment} when is_binary(redirect_url) ->
            {:ok,
             %{
               redirect_url: redirect_url,
               order_id: payment["order_id"],
               amount_idr: payment["amount_idr"],
               status: payment["status"]
             }}

          _ ->
            {:error, :unavailable}
        end

      {:ok, %{status: status}} when status in [422, 503] ->
        # Invalid request or gateway down — treat identically on the public
        # side (graceful fallback), but log for diagnosis.
        Logger.warning(
          "[EventPayments] start_payment rejected by atrium (status=#{status}, event=#{event_id})"
        )

        {:error, :unavailable}

      {:ok, %{status: status}} ->
        Logger.warning("[EventPayments] unexpected status from atrium: #{status}")
        {:error, :unavailable}

      {:error, reason} ->
        Logger.error("[EventPayments] atrium unreachable: #{inspect(reason)}")
        {:error, :unavailable}
    end
  end

  @doc """
  Pushes a participant's registration-form data (name, phone) to their atrium
  profile so every later page resolves their real identity.

  Fire-and-forget style: failures are logged and returned as
  `{:error, :unavailable}` without raising.
  """
  def sync_profile(user_id, name, phone) do
    api_key = System.get_env("INTERNAL_API_KEY")

    if is_binary(api_key) and api_key != "" do
      do_sync_profile(api_key, user_id, name, phone)
    else
      {:error, :not_configured}
    end
  end

  defp do_sync_profile(api_key, user_id, name, phone) do
    base_url = Application.get_env(:curatorian, :atrium_url, "http://localhost:4001")
    url = String.trim_trailing(base_url, "/") <> @profiles_path

    body = %{"user_id" => user_id}
    body = if name in [nil, ""], do: body, else: Map.put(body, "name", name)
    body = if phone in [nil, ""], do: body, else: Map.put(body, "phone", phone)

    request =
      Finch.build(
        :post,
        url,
        [
          {"x-internal-key", api_key},
          {"content-type", "application/json"},
          {"accept", "application/json"}
        ],
        Jason.encode!(body)
      )

    case Finch.request(request, Curatorian.Finch, receive_timeout: @timeout) do
      {:ok, %{status: 200}} ->
        {:ok, :synced}

      {:ok, %{status: status}} ->
        Logger.warning("[EventPayments] profile sync rejected by atrium (status=#{status})")
        {:error, :unavailable}

      {:error, reason} ->
        Logger.error("[EventPayments] profile sync unreachable: #{inspect(reason)}")
        {:error, :unavailable}
    end
  end
end
