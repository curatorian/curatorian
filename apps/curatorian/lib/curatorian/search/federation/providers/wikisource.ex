defmodule Curatorian.Search.Federation.Providers.Wikisource do
  @moduledoc """
  Indonesian Wikisource provider — spec §9.6, Tier 2.

  Public-domain texts in Indonesian via the MediaWiki search API:

      GET https://id.wikisource.org/w/api.php
          ?action=query&list=search&srsearch=…&srlimit=8&format=json&formatversion=2

  Wikimedia policy requires an identifying User-Agent with contact info — the
  shared UA from `Provider.user_agent/0` satisfies it. Snippets contain HTML
  (`<span class="searchmatch">`), so text goes through `plain_text/1`.
  """

  @behaviour Curatorian.Search.Federation.Provider

  alias Curatorian.Search.Federation.Provider
  alias Curatorian.Search.{Query, Result}

  @impl true
  def id, do: :wikisource

  @impl true
  def label, do: "Wikisource"

  @impl true
  def kinds, do: [:all, :book]

  @doc "Default upstream base URL (overridable via config/testing stubs)."
  def base_url,
    do:
      Application.get_env(:curatorian, __MODULE__, [])
      |> Keyword.get(:base_url, "https://id.wikisource.org")

  @impl true
  def enabled?, do: config(:enabled, true)

  @impl true
  def rate_limit, do: {1, 2}

  @impl true
  def timeout, do: 4_000

  @impl true
  def search(%Query{} = query) do
    client = Req.new(Provider.req_options(__MODULE__))

    params = [
      action: "query",
      list: "search",
      srsearch: query.text,
      srlimit: min(query.per_page, 10),
      sroffset: (query.page - 1) * min(query.per_page, 10),
      format: "json",
      formatversion: "2"
    ]

    case Req.get(client, url: "/w/api.php", params: params) do
      {:ok, %{status: 200, body: raw}} ->
        with {:ok, body} <- Provider.decode_json(raw) do
          {:ok, page(body, query)}
        else
          {:error, :invalid_json} -> {:error, :invalid_json}
        end

      {:ok, %{status: 429, headers: headers}} ->
        {:error, {:rate_limited, Provider.retry_after_seconds(headers)}}

      {:ok, %{status: status}} ->
        {:error, {:upstream_status, status}}

      {:error, %{reason: reason}} ->
        {:error, {:req, reason}}

      {:error, other} ->
        {:error, {:req, other}}
    end
  rescue
    e -> {:error, {:exception, Exception.message(e)}}
  end

  @impl true
  def more_url(text),
    do: "https://id.wikisource.org/w/index.php?search=" <> URI.encode_www_form(text)

  defp page(body, query) do
    search = get_in(body, ["query", "search"]) || []
    total = get_in(body, ["query", "searchinfo", "totalhits"])

    results =
      search
      |> Enum.map(&normalize/1)
      |> Enum.reject(&is_nil/1)

    %{results: results, total: total, more_url: more_url(query.text)}
  end

  @doc "Normalizer — pure, nil-safe (spec §9.6)."
  def normalize(item) when is_map(item) do
    title = item["title"]

    if is_binary(title) and title != "" do
      Result.new(%{
        source: :wikisource,
        source_id: to_string(item["pageid"] || title),
        title: Provider.plain_text(title),
        url: page_url(title),
        creators: [],
        year: nil,
        kind: :book,
        description: Provider.plain_text(item["snippet"]),
        thumbnail_url: nil,
        languages: ["id"],
        access: :open,
        rights: "Teks domain publik (Wikisource)"
      })
    end
  end

  def normalize(_), do: nil

  @doc "Wiki page URL — spaces become underscores, subpage slashes survive."
  def page_url(title), do: "https://id.wikisource.org/wiki/" <> Provider.wiki_encode(title)

  defp config(key, default) do
    Application.get_env(:curatorian, __MODULE__, []) |> Keyword.get(key, default)
  end
end
