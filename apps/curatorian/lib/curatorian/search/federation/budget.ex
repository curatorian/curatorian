defmodule Curatorian.Search.Federation.Budget do
  @moduledoc """
  Daily-budget guard for OpenAlex (spec §9.3, §8.7.7).

  OpenAlex budgets are expressed in **USD/day**, not call counts — never
  hardcode numbers, re-derive them at runtime:

  * Polls `GET /rate-limit` on boot and every 10 minutes when a key is
    configured (D9: state is node-local in ETS, lost on restart, re-derived).
  * `status/0`:
    * `:ok`        — remaining >= 25%
    * `:degraded`  — remaining < 25%: no auto-query in the `all` view, but
                     `kind=article` and explicit retries still call upstream
    * `:exhausted` — remaining < 10% or the API said "daily budget spent":
                     no calls until `resets_at`
    * `:unavailable` — no API key configured (provider is disabled anyway)
  * `mark_exhausted/1` is called by the provider on a daily-budget 429.
  * Reset times are shown in WIB (UTC+7) in the UI.
  """

  use GenServer

  @table :curatorian_search_budget
  @poll_interval :timer.minutes(10)
  @degrade_threshold 0.25
  @stop_threshold 0.10

  alias Curatorian.Search.Federation.Providers.OpenAlex

  # --- public API ---

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "Budget status for routing/UI decisions: `:ok | :degraded | :exhausted | :unavailable`."
  def status do
    case state() do
      %{exhausted_until: until} when is_integer(until) ->
        if now_s() >= until, do: :ok, else: :exhausted

      %{status: status} ->
        status

      nil ->
        if OpenAlex.api_key(), do: :ok, else: :unavailable
    end
  end

  def exhausted?, do: status() == :exhausted

  @doc "Unix seconds when the daily budget resets, if known."
  def resets_at do
    case state() do
      %{exhausted_until: until} when is_integer(until) -> until
      %{resets_at: resets_at} when is_integer(resets_at) -> resets_at
      _ -> nil
    end
  end

  @doc "Remaining budget fraction (0.0..1.0), or `nil` when unknown."
  def remaining_fraction do
    case state() do
      %{budget_usd: budget, remaining_usd: remaining}
      when is_number(budget) and is_number(remaining) and budget > 0 ->
        max(0.0, remaining / budget)

      _ ->
        nil
    end
  end

  @doc "Called by the OpenAlex provider when a daily-budget 429 is seen."
  def mark_exhausted(resets_at \\ nil) do
    until = resets_at || default_reset_unix()

    :ets.insert(
      @table,
      {:openalex,
       %{
         status: :exhausted,
         exhausted_until: until,
         resets_at: until,
         budget_usd: nil,
         used_usd: nil,
         remaining_usd: 0.0,
         updated_at: now_s()
       }}
    )

    :ok
  end

  @doc "Reset to unknown/ok state (used by tests and after a key change)."
  def clear do
    :ets.delete(@table, :openalex)
    :ok
  end

  @doc "Force a poll now (called on boot, by tests, and every 10 minutes)."
  def poll_now, do: GenServer.cast(__MODULE__, :poll)

  # --- GenServer ---

  @impl true
  def init(_opts) do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    end

    if OpenAlex.api_key() && Application.get_env(:curatorian, :budget_poll_on_boot, true) do
      send(self(), :poll)
    end

    {:ok, %{timer: nil}}
  end

  @impl true
  def handle_cast(:poll, state) do
    poll()
    {:noreply, state}
  end

  @impl true
  def handle_info(:poll, state) do
    poll()
    Process.send_after(self(), :poll, @poll_interval)
    {:noreply, state}
  end

  def handle_info(_message, state), do: {:noreply, state}

  # --- internals ---

  defp state do
    case :ets.lookup(@table, :openalex) do
      [{_id, state}] -> state
      [] -> nil
    end
  end

  defp poll do
    key = OpenAlex.api_key()

    if key do
      opts = OpenAlex.budget_req_options()

      case Req.get(opts, url: "/rate-limit") do
        {:ok, %{status: 200, body: raw}} ->
          with {:ok, body} <- Curatorian.Search.Federation.Provider.decode_json(raw) do
            store_from_rate_limit(body)
          else
            _ -> :ok
          end

        _ ->
          # Keep the last known state — a failed poll must not unlock calls.
          :ok
      end
    else
      :ok
    end
  end

  defp store_from_rate_limit(body) do
    # The live API nests everything under "rate_limit" (2026); older/shorter
    # shapes are tolerated by falling back to the top-level body.
    limits = body["rate_limit"] || body

    budget = number(limits["daily_budget_usd"]) || number(limits["budget_usd"])
    used = number(limits["daily_used_usd"]) || number(limits["used_usd"])

    remaining =
      number(limits["daily_remaining_usd"]) ||
        number(limits["remaining_usd"]) ||
        if(is_number(budget) and is_number(used), do: budget - used)

    resets_at =
      parse_time(limits["resets_at"]) ||
        resets_in_to_unix(number(limits["resets_in_seconds"]))

    status =
      cond do
        not is_number(remaining) -> :ok
        not is_number(budget) or budget <= 0 -> :ok
        remaining / budget < @stop_threshold -> :exhausted
        remaining / budget < @degrade_threshold -> :degraded
        true -> :ok
      end

    :ets.insert(
      @table,
      {:openalex,
       %{
         status: status,
         budget_usd: budget,
         used_usd: used,
         remaining_usd: remaining,
         resets_at: resets_at,
         exhausted_until: if(status == :exhausted, do: resets_at),
         updated_at: now_s()
       }}
    )

    :ok
  end

  defp number(n) when is_number(n), do: n

  defp number(n) when is_binary(n) do
    case Float.parse(n) do
      {f, _} -> f
      :error -> nil
    end
  end

  defp number(_), do: nil

  # Newer responses include resets_in_seconds but may omit/rename resets_at.
  defp resets_in_to_unix(nil), do: nil
  defp resets_in_to_unix(seconds) when is_number(seconds), do: now_s() + trunc(seconds)
  defp resets_in_to_unix(_), do: nil

  defp parse_time(nil), do: nil
  defp parse_time(n) when is_integer(n), do: n
  defp parse_time(n) when is_number(n), do: trunc(n)

  defp parse_time(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> DateTime.to_unix(dt)
      _ -> nil
    end
  end

  defp parse_time(_), do: nil

  defp default_reset_unix do
    # OpenAlex resets at midnight UTC; the UI shows it in WIB (§8.7).
    date = DateTime.utc_now() |> DateTime.to_date() |> Date.add(1)
    {:ok, midnight} = DateTime.new(date, ~T[00:00:00], "Etc/UTC")
    DateTime.to_unix(midnight)
  end

  defp now_s, do: System.system_time(:second)
end
