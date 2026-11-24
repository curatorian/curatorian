defmodule Curatorian.Search.Federation.Limiter do
  @moduledoc """
  Per-provider token bucket (spec §8.3.2), sized below the provider's
  published limit (Open Library 2 req/s burst 3, Internet Archive 1 req/s
  burst 2 — see §9). State in ETS, refilled lazily by elapsed time.
  """

  def check(provider_id, {rate, burst}) do
    now = System.system_time(:millisecond)

    {tokens, last} =
      case :ets.lookup(:curatorian_search_limiter, provider_id) do
        [{_id, {tokens, last}}] -> {tokens, last}
        [] -> {burst * 1.0, now}
      end

    elapsed_s = max(0, now - last) / 1000
    refilled = min(burst * 1.0, tokens + elapsed_s * rate)

    if refilled >= 1 do
      :ets.insert(:curatorian_search_limiter, {provider_id, {refilled - 1, now}})
      :ok
    else
      :ets.insert(:curatorian_search_limiter, {provider_id, {refilled, now}})
      wait_ms = ceil((1 - refilled) / rate * 1000)
      {:limited, max(1, wait_ms)}
    end
  end

  def reset(provider_id), do: :ets.delete(:curatorian_search_limiter, provider_id)
end
