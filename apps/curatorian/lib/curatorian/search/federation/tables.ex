defmodule Curatorian.Search.Federation.Tables do
  @moduledoc """
  Owns the named ETS tables backing the federation runtime (spec §8.3, D9).

  One supervised GenServer creates all tables; state is in-memory and
  node-local by design (single-node deployment). Tables are `:public` so the
  LiveView async-task processes can read/write without round-trips; mutation
  races are benign by construction (claims use `insert_new`, counters are
  advisory).

  * `:curatorian_search_cache`   — result/negative cache entries
  * `:curatorian_search_breaker` — circuit breaker state per provider
  * `:curatorian_search_limiter` — token bucket per provider
  * `:curatorian_search_cooldown`— provider-wide 429 cooldowns
  * `:curatorian_search_claims`  — single-flight in-progress claims
  """

  use GenServer

  @tables [
    :curatorian_search_cache,
    :curatorian_search_breaker,
    :curatorian_search_limiter,
    :curatorian_search_cooldown,
    :curatorian_search_claims
  ]

  @cache_cap 5_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    for table <- @tables do
      :ets.new(table, [:named_table, :set, :public, read_concurrency: true])
    end

    {:ok, %{}}
  end

  @doc "Lazy-trim the cache when it exceeds its cap (approximate eviction)."
  def trim_cache do
    case :ets.info(:curatorian_search_cache, :size) do
      size when is_integer(size) and size > @cache_cap ->
        Enum.each(1..(size - @cache_cap), fn _ ->
          case :ets.first(:curatorian_search_cache) do
            :"$end_of_table" -> :ok
            key -> :ets.delete(:curatorian_search_cache, key)
          end
        end)

        :ok

      _ ->
        :ok
    end
  end
end
