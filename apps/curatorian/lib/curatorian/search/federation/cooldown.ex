defmodule Curatorian.Search.Federation.Cooldown do
  @moduledoc """
  Provider-wide cooldown after upstream 429s (spec §8.7.2).

  A 429 puts the whole provider in cooldown — shared state in ETS so every
  session respects it — and during cooldown **no upstream calls** are made.
  Cooldown = `Retry-After` clamped to 5..300 s plus ±20% jitter.
  """

  @min_s 5
  @max_s 300

  def set(provider_id, retry_after_s) when is_integer(retry_after_s) and retry_after_s > 0 do
    seconds = retry_after_s |> jitter() |> max(@min_s) |> min(@max_s)
    :ets.insert(:curatorian_search_cooldown, {provider_id, now_ms() + seconds * 1000})
    {:ok, seconds}
  end

  def set(provider_id, _), do: set(provider_id, 30)

  def check(provider_id) do
    now = now_ms()

    case :ets.lookup(:curatorian_search_cooldown, provider_id) do
      [{_id, until}] when now < until -> {:limited, div(until - now, 1000) + 1}
      _ -> :ok
    end
  end

  def remaining_s(provider_id) do
    case check(provider_id) do
      {:limited, s} -> s
      :ok -> 0
    end
  end

  def clear(provider_id), do: :ets.delete(:curatorian_search_cooldown, provider_id)

  defp jitter(seconds) do
    delta = div(seconds, 5)
    seconds + (:rand.uniform(2 * delta + 1) - delta - 1)
  end

  defp now_ms, do: System.system_time(:millisecond)
end
