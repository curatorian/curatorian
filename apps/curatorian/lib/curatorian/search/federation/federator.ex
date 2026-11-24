defmodule Curatorian.Search.Federation.Federator do
  @moduledoc """
  Orchestrates one external provider call (spec §8.3, 8.7):

  enabled? → cooldown → breaker → limiter → cache (single-flight, negative
  cache, stale-if-error) → `provider.search/1` → telemetry.

  Local results never wait on or change because of this — the LiveView calls
  it from `start_async` tasks, one per provider.

  Returns:

      {:ok, %{status: :ok | :empty | :stale, results: [...], total, more_url,
              took_ms, stale_age_min}}
      {:error, %{status: :rate_limited | :breaker_open | :error | :disabled,
                 retry_after: seconds | nil}}
  """

  alias Curatorian.Search.Federation.{Breaker, Cache, Cooldown, Limiter}
  alias Curatorian.Search.Query

  @error_cooldown_default 30

  def run(provider, %Query{} = query, opts \\ []) do
    id = provider.id()
    start = System.monotonic_time(:millisecond)

    result =
      cond do
        not provider.enabled?() -> disabled(id)
        Cooldown.check(id) != :ok -> rate_limited(provider, id, start)
        Breaker.check(id) != :ok -> breaker_open(id, start)
        bypass?(opts) -> bypass_fetch(provider, query, id, start)
        true -> cached_fetch(provider, query, id, start)
      end

    emit_telemetry(id, result, start)
    result
  end

  # --- main paths ---

  defp bypass_fetch(provider, query, id, start) do
    key = Cache.key(id, query)
    Cache.delete(key)
    cached_fetch(provider, query, id, start)
  end

  defp cached_fetch(provider, query, id, start) do
    key = Cache.key(id, query)

    case Cache.fetch(key, fn -> call_provider(provider, query, id) end) do
      {:fresh, {:error, reason}} ->
        # Negatively cached — report error, offer stale if present (§8.7.1).
        serve_stale_or_error(provider, query, id, start, reason)

      {origin, {:ok, page}} ->
        Breaker.record_success(id)
        {:ok, build_page(page, origin, start)}

      {origin, {:error, reason}} when origin in [:computed, :waited] ->
        maybe_cooldown(id, reason)

        case reason do
          # Expected limit states are not provider-health failures (§8.7).
          {:rate_limited, _} -> :ok
          {:self_limited, _} -> :ok
          {:budget, _} -> :ok
          _ -> Breaker.record_failure(id)
        end

        serve_stale_or_error(provider, query, id, start, reason)
    end
  end

  defp call_provider(provider, query, id) do
    case Limiter.check(id, provider.rate_limit()) do
      :ok ->
        with_hard_timeout(provider, query)

      {:limited, wait_ms} ->
        # Our own bucket is empty — tell the caller to retry (§8.7).
        {:error, {:self_limited, ceil(wait_ms / 1000)}}
    end
  end

  # Transport timeouts can leak (DNS/TLS hangs above the provider's receive
  # timeout), so enforce the provider's timeout as a hard ceiling: one slow
  # provider must never delay its block beyond its budget (§8.2).
  defp with_hard_timeout(provider, query) do
    timeout = provider.timeout() + 1_000
    task = Task.async(fn -> provider.search(query) end)

    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      _ -> {:error, :timeout}
    end
  end

  defp serve_stale_or_error(_provider, query, id, start, reason) do
    key = Cache.key(id, query)

    case Cache.peek(key) do
      {:stale, {:ok, page}, age_min} ->
        {:ok, build_page(page, :stale, start, %{stale_age_min: age_min})}

      _ ->
        {:error, error_status(id, reason, start)}
    end
  end

  defp disabled(id), do: {:error, %{status: :disabled, provider: id}}
  defp breaker_open(id, _start), do: {:error, %{status: :breaker_open, provider: id}}

  defp rate_limited(_provider, id, _start) do
    {:error, %{status: :rate_limited, provider: id, retry_after: Cooldown.remaining_s(id)}}
  end

  defp build_page(page, origin, start, extra \\ %{}) do
    status =
      cond do
        origin == :stale -> :stale
        page.results == [] -> :empty
        origin == :fresh -> :cache_hit
        true -> :ok
      end

    Map.merge(
      %{
        status: status,
        results: page.results,
        total: Map.get(page, :total),
        more_url: page.more_url,
        took_ms: System.monotonic_time(:millisecond) - start
      },
      extra
    )
  end

  defp error_status(id, reason, _start) do
    base = %{provider: id}

    case reason do
      {:self_limited, wait_s} ->
        Map.merge(base, %{status: :rate_limited, retry_after: wait_s})

      {:rate_limited, retry_after} ->
        Map.merge(base, %{status: :rate_limited, retry_after: retry_after_s(retry_after)})

      {:budget, resets_at} ->
        Map.merge(base, %{status: :budget, resets_at: resets_at})

      :timeout ->
        Map.merge(base, %{status: :error, reason: :timeout})

      other ->
        Map.merge(base, %{status: :error, reason: other_kind(other)})
    end
  end

  defp retry_after_s(s) when is_integer(s) and s > 0, do: s
  defp retry_after_s(_), do: @error_cooldown_default

  defp other_kind({:exception, _}), do: :exception
  defp other_kind({:exit, _}), do: :exception
  defp other_kind(_), do: :unknown

  defp maybe_cooldown(id, {:rate_limited, retry_after}) do
    # Only a real upstream 429 triggers the provider-wide cooldown (§8.7.2).
    Cooldown.set(id, retry_after)
  end

  defp maybe_cooldown(_id, _reason), do: :ok

  defp bypass?(opts), do: Keyword.get(opts, :bypass_cache, false)

  defp emit_telemetry(id, result, start) do
    duration = System.monotonic_time(:millisecond) - start

    {status, result_count} =
      case result do
        {:ok, page} -> {page.status, length(page.results)}
        {:error, %{status: s}} -> {s, 0}
      end

    :telemetry.execute([:curatorian, :search, :provider, :stop], %{duration: duration}, %{
      provider: id,
      status: status,
      result_count: result_count
    })
  end
end
