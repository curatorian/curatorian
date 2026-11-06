defmodule Curatorian.SEO.SitemapCache do
  @moduledoc """
  Caches the rendered URL list for /sitemap.xml in an ETS table.

  The sitemap is built at boot and refreshed every `@refresh_hours`. Reads
  never touch the database unless the cache is empty (then it builds on
  demand as a fallback).
  """

  use GenServer
  require Logger

  alias Curatorian.SEO.Sitemap

  @table :curatorian_sitemap_cache
  @refresh_hours 6

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def urls do
    case :ets.lookup(@table, :urls) do
      [{:urls, urls}] -> urls
      [] -> refresh()
    end
  end

  def refresh do
    urls = Sitemap.build()
    :ets.insert(@table, {:urls, urls})
    urls
  rescue
    e ->
      Logger.error("Sitemap build failed: #{Exception.message(e)}")
      []
  end

  @impl true
  def init(_opts) do
    :ets.new(@table, [:set, :named_table, read_concurrency: true])
    send(self(), :refresh)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:refresh, state) do
    refresh()
    Process.send_after(self(), :refresh, :timer.hours(@refresh_hours))
    {:noreply, state}
  end
end
