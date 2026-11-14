defmodule Curatorian.RateLimiter do
  @moduledoc """
  ETS-backed sliding-window rate limiter.

  Tracks per-key event counts within a rolling time window. Used to slow down
  abuse of public surfaces (registration, login, confirmation emails, comments)
  independent of Turnstile.

  Started as a supervised GenServer so it owns the ETS table and cleans up
  stale entries periodically. Node-local by design — resets on restart and is
  per-node when horizontally scaled (acceptable for the current deployment).
  """

  use GenServer

  @table :curatorian_rate_limiter
  @max_window 3600
  # Clean up old entries every 5 minutes
  @cleanup_interval :timer.minutes(5)

  # --- Public API ---

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Returns `:ok` if `id` (user id, IP string, or any term) is within `limit`
  events per `window_seconds` for `scope`, else `{:error, :rate_limited}.

  Uses a sliding window over the timestamps of recent events.
  """
  def check(scope, id, limit, window_seconds) do
    key = {scope, id}
    now = System.system_time(:second)
    cutoff = now - window_seconds

    timestamps =
      case :ets.lookup(@table, key) do
        [{^key, ts}] -> ts
        [] -> []
      end

    recent = Enum.filter(timestamps, &(&1 > cutoff))

    if length(recent) >= limit do
      {:error, :rate_limited}
    else
      :ets.insert(@table, {key, [now | recent]})
      :ok
    end
  end

  # --- GenServer callbacks ---

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    now = System.system_time(:second)
    # Remove any key whose newest timestamp is older than the longest window
    :ets.select_delete(@table, [
      {{:_, :"$1"}, [{:<, {:hd, :"$1"}, now - @max_window * 2}], [true]}
    ])

    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end
