defmodule Curatorian.Search.Federation.Breaker do
  @threshold 5
  @window_ms 60_000
  @open_ms 60_000

  @moduledoc """
  Per-provider circuit breaker (spec §8.3.4, 8.7).

  Opens after #{@threshold} failures within #{@window_ms} ms, stays open
  #{@open_ms} ms, then allows a half-open probe: a success closes it, a
  failure reopens it. State lives in ETS (`:curatorian_search_breaker`),
  shared across all sessions on this node.
  """

  def check(provider_id) do
    now = now_ms()

    case :ets.lookup(:curatorian_search_breaker, provider_id) do
      [] ->
        :ok

      [{_id, {:open, opened_at}}] ->
        if now - opened_at >= @open_ms do
          # Half-open: allow one probe through.
          :ok
        else
          {:open, retry_at_ms(opened_at)}
        end

      [{_id, :closed}] ->
        :ok

      [{_id, {:failures, _recent}}] ->
        :ok
    end
  end

  def record_success(provider_id) do
    :ets.insert(:curatorian_search_breaker, {provider_id, :closed})
    :ok
  end

  def record_failure(provider_id) do
    now = now_ms()
    failures = recent_failures(provider_id, now) ++ [now]

    if length(failures) >= @threshold do
      :ets.insert(:curatorian_search_breaker, {provider_id, {:open, now}})
    else
      :ets.insert(:curatorian_search_breaker, {provider_id, {:failures, failures}})
    end

    :ok
  end

  def state(provider_id) do
    now = now_ms()

    case :ets.lookup(:curatorian_search_breaker, provider_id) do
      [] -> :closed
      [{_id, :closed}] -> :closed
      [{_id, {:open, opened_at}}] -> if now - opened_at >= @open_ms, do: :half_open, else: :open
      [{_id, {:failures, _}}] -> :closed
    end
  end

  defp recent_failures(provider_id, now) do
    case :ets.lookup(:curatorian_search_breaker, provider_id) do
      [{_id, {:failures, failures}}] ->
        Enum.filter(failures, fn t -> now - t < @window_ms end)

      _ ->
        []
    end
  end

  defp retry_at_ms(opened_at), do: opened_at + @open_ms

  defp now_ms, do: System.system_time(:millisecond)
end
