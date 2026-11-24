defmodule Curatorian.Search.Federation.Cache do
  @moduledoc """
  Federation result cache (spec §8.3.1, 8.7.1).

  * Fresh TTL 6 h for results, 60 s for errors (negative cache).
  * Entries stay in the table for 24 h after going stale — the Federator
    serves them as "stale" **only** when the provider is in a non-OK state,
    never for a different query key.
  * Single-flight: on a miss, one process claims the key (`insert_new`); the
    loser polls for the winner's entry instead of calling upstream (bounded
    by the provider timeout).
  """

  @fresh_ttl_ms :timer.hours(6)
  @error_ttl_ms :timer.minutes(1)
  @stale_until_ms :timer.hours(24)
  @wait_timeout_ms 6_000
  @wait_poll_ms 25

  alias Curatorian.Search.Federation.Tables

  @doc """
  Cache key from provider id + query (§8.3.1: normalized text, languages,
  kind, open_only, page).
  """
  def key(provider_id, query) do
    {provider_id, String.downcase(query.text), Enum.sort(query.languages), query.kind,
     query.open_only, query.page, query.per_page}
  end

  @type peek :: :miss | {:fresh, term()} | {:stale, term(), non_neg_integer()}

  @doc "Look up an entry. `{:stale, value, age_min}` entries are past their fresh TTL."
  @spec peek(term()) :: peek()
  def peek(key) do
    now = now_ms()

    case :ets.lookup(:curatorian_search_cache, key) do
      [{_key, {value, fresh_until, stale_until, fetched_at}}] ->
        cond do
          now < fresh_until -> {:fresh, value}
          now < stale_until -> {:stale, value, max(1, div(now - fetched_at, 60_000))}
          true -> :miss
        end

      _ ->
        :miss
    end
  end

  @doc """
  Single-flight fetch. Runs `loader` once per key; concurrent callers share
  the result. Returns `{origin, result}` where origin is `:fresh` (cache hit)
  or `:computed` / `:waited` (this caller or another did the upstream call).
  """
  @spec fetch(term(), (-> term()), keyword()) :: {:fresh | :computed | :waited, term()}
  def fetch(key, loader, opts \\ []) do
    case peek(key) do
      {:fresh, value} ->
        {:fresh, value}

      _miss_or_stale ->
        # Capture any stale data first: if the upstream call fails, the stale
        # entry must survive so stale-if-error can serve it (§8.7.1).
        prior = raw_entry(key)
        ref = make_ref()

        # Claims live in their own table so claiming never deletes data that
        # another process may still be serving.
        if :ets.insert_new(:curatorian_search_claims, {key, ref}) do
          try do
            result = run_loader(loader)
            finalize(key, result, prior, opts)
            {:computed, result}
          after
            :ets.delete(:curatorian_search_claims, key)
          end
        else
          wait_for(key)
        end
    end
  end

  @doc "Store a successful value with the fresh/stale windows."
  def put_ok(key, value, opts \\ []) do
    now = now_ms()
    fresh_until = now + Keyword.get(opts, :fresh_ms, @fresh_ttl_ms)
    stale_until = now + Keyword.get(opts, :stale_ms, @stale_until_ms)
    :ets.insert(:curatorian_search_cache, {key, {value, fresh_until, stale_until, now}})
    Tables.trim_cache()
    :ok
  end

  @doc "Store a negative (error) result — 60 s TTL, no stale window (§8.3.1)."
  def put_error(key, reason) do
    now = now_ms()
    ttl = now + @error_ttl_ms
    :ets.insert(:curatorian_search_cache, {key, {{:error, reason}, ttl, ttl, now}})
    :ok
  end

  @doc "Drop an entry (manual retry bypassing the negative cache, §8.7.4)."
  def delete(key), do: :ets.delete(:curatorian_search_cache, key)

  # --- internals ---

  defp run_loader(loader) do
    loader.()
  rescue
    e -> {:error, {:exception, Exception.message(e)}}
  catch
    :exit, reason -> {:error, {:exit, reason}}
  end

  # The cache stores the *result tuple* as-is, so callers pattern-match the
  # same shape whether it came from the cache or upstream.
  defp finalize(key, result, prior, opts) do
    case result do
      {:ok, _page} ->
        put_ok(key, result, opts)

      {:error, reason} ->
        if servable_stale?(prior) do
          # Keep usable stale data; do not negative-cache over it.
          :ets.insert(:curatorian_search_cache, {key, prior})
        else
          put_error(key, reason)
        end
    end
  end

  defp raw_entry(key) do
    case :ets.lookup(:curatorian_search_cache, key) do
      [{_key, {_value, _fresh, _stale, _at} = entry}] -> entry
      _ -> nil
    end
  end

  defp servable_stale?({value, fresh_until, stale_until, _at}) do
    match?({:ok, _}, value) and now_ms() >= fresh_until and now_ms() < stale_until
  end

  defp servable_stale?(_), do: false

  defp wait_for(key) do
    deadline = now_ms() + @wait_timeout_ms
    do_wait(key, deadline)
  end

  defp do_wait(key, deadline) do
    case peek(key) do
      {:fresh, value} ->
        {:waited, value}

      # Winner errored but stale data survived — the Federator decides whether
      # to serve it as stale (it re-checks provider state).
      {:stale, value, _age} ->
        if claim_gone?(key), do: {:waited, value}, else: wait_more(key, deadline)

      :miss ->
        if claim_gone?(key) do
          {:waited, {:error, :no_result}}
        else
          wait_more(key, deadline)
        end
    end
  end

  defp wait_more(key, deadline) do
    if now_ms() >= deadline do
      {:waited, {:error, :single_flight_timeout}}
    else
      Process.sleep(@wait_poll_ms)
      do_wait(key, deadline)
    end
  end

  defp claim_gone?(key), do: :ets.lookup(:curatorian_search_claims, key) == []

  defp now_ms, do: System.system_time(:millisecond)
end
