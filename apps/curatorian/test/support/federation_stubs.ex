defmodule Curatorian.FederationStubs.Provider do
  @moduledoc """
  Configurable stub provider for federation runtime tests. Behaviour and
  results come from the application env, so each test can drive it:
  `:stub_search_result` is `:ok`, `{:ok, results}`, `{:error, reason}` or
  `{:sleep, ms, result}`.
  """

  @behaviour Curatorian.Search.Federation.Provider

  alias Curatorian.Search.Result

  @impl true
  def id, do: Application.get_env(:curatorian, :stub_provider_id, :stub_provider)

  @impl true
  def label, do: "Stub Provider"

  @impl true
  def kinds, do: [:all, :book]

  @impl true
  def enabled?, do: true

  @impl true
  def rate_limit, do: Application.get_env(:curatorian, :stub_rate_limit, {100, 100})

  @impl true
  def timeout, do: 500

  @impl true
  def search(_query) do
    bump_calls()

    case Application.get_env(:curatorian, :stub_search_result, :ok) do
      :ok ->
        {:ok, page()}

      {:ok, results} ->
        {:ok, page(results)}

      {:error, reason} ->
        {:error, reason}

      {:sleep, ms, result} ->
        Process.sleep(ms)
        result
    end
  end

  def page(results \\ nil) do
    results = results || [result()]
    %{results: results, total: length(results), more_url: "https://stub.example/search"}
  end

  def result(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      source: :stub_provider,
      source_id: "stub-#{System.unique_integer([:positive])}",
      title: "Stub result",
      url: "https://stub.example/1"
    })
    |> Result.new()
  end

  def calls do
    if :ets.whereis(:stub_call_counter) == :undefined do
      0
    else
      :ets.lookup_element(:stub_call_counter, :calls, 2)
    end
  end

  defp bump_calls do
    if :ets.whereis(:stub_call_counter) != :undefined do
      :ets.update_counter(:stub_call_counter, :calls, {2, 1}, {:calls, 0})
    end
  end
end
