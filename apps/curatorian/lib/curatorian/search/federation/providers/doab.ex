defmodule Curatorian.Search.Federation.Providers.Doab do
  @moduledoc """
  DOAB (Directory of Open Access Books) provider — spec §9.5, Tier 2.

  DSpace-style REST: `GET /rest/search?query=...&expand=metadata&limit=8&offset=0`
  with `Accept: application/json`. Metadata arrives as a list of
  `{key, value, language}` objects (Dublin Core), so all field access goes
  through `meta_values/2`.

  Best Indonesian-scholarly fit among the book sources (§9.5) — good candidate
  to promote above Gutendex once evaluated with real queries.
  """

  @behaviour Curatorian.Search.Federation.Provider

  alias Curatorian.Search.Federation.Provider
  alias Curatorian.Search.{Query, Result}

  @impl true
  def id, do: :doab

  @impl true
  def label, do: "DOAB"

  @impl true
  def kinds, do: [:all, :book]

  @doc "Default upstream base URL (overridable via config/testing stubs)."
  def base_url, do: config(:base_url, "https://directory.doabooks.org")

  @impl true
  def enabled?, do: config(:enabled, false)

  @impl true
  def rate_limit, do: {1, 2}

  @impl true
  def timeout, do: 5_000

  @impl true
  def search(%Query{} = query) do
    client =
      Req.new(
        Provider.req_options(__MODULE__)
        |> Keyword.put(:headers, [{"accept", "application/json"}])
      )

    params = [query: query.text, expand: "metadata", limit: min(query.per_page, 10), offset: 0]

    case Req.get(client, url: "/rest/search", params: params) do
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
    do: "https://directory.doabooks.org/discover?query=" <> URI.encode_www_form(text)

  defp page(body, query) do
    items =
      cond do
        is_list(body) -> body
        is_list(body["items"]) -> body["items"]
        true -> []
      end

    results =
      items
      |> Enum.map(&normalize/1)
      |> Enum.reject(&is_nil/1)

    %{
      results: results,
      total: if(is_map(body), do: body["totalElements"]),
      more_url: more_url(query.text)
    }
  end

  @doc "Normalizer for one DSpace item; nil-safe, never raises (spec §9.5)."
  def normalize(item) when is_map(item) do
    metadata = item["metadata"] || []

    title = meta_first(metadata, "dc.title")
    url = item_url(item, metadata)

    if is_binary(title) and title != "" and is_binary(url) do
      Result.new(%{
        source: :doab,
        source_id: to_string(item["uuid"] || item["handle"] || url),
        title: Provider.plain_text(title),
        url: url,
        creators: meta_values(metadata, "dc.contributor.author"),
        year: year(meta_first(metadata, "dc.date.issued")),
        kind: :book,
        description: Provider.plain_text(meta_first(metadata, "dc.description.abstract")),
        thumbnail_url: nil,
        languages: meta_values(metadata, "dc.language") |> Enum.uniq(),
        access: :open,
        rights: meta_first(metadata, "dc.rights.uri") || meta_first(metadata, "dc.rights"),
        read_url: first_read_url(metadata, item),
        identifiers: %{handle: Enum.filter([item["handle"]], &is_binary/1)}
      })
    end
  end

  def normalize(_), do: nil

  @doc "All values for a Dublin Core key, in document order."
  def meta_values(metadata, key) when is_list(metadata) do
    metadata
    |> Enum.filter(fn
      %{"key" => ^key, "value" => value} when is_binary(value) -> true
      _ -> false
    end)
    |> Enum.map(& &1["value"])
  end

  def meta_values(_metadata, _key), do: []

  defp meta_first(metadata, key), do: List.first(meta_values(metadata, key))

  defp item_url(item, metadata) do
    meta_first(metadata, "dc.identifier.uri") ||
      (is_binary(item["handle"]) && "https://directory.doabooks.org/handle/#{item["handle"]}") ||
      item["link"] ||
      nil
  end

  defp first_read_url(metadata, item) do
    meta_first(metadata, "dc.identifier.pdf") ||
      meta_first(metadata, "dc.identifier.uri") ||
      item["link"]
  end

  defp year(nil), do: nil

  defp year(value) when is_binary(value) do
    case Integer.parse(String.slice(value, 0, 4)) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp year(value) when is_integer(value), do: value
  defp year(_), do: nil

  defp config(key, default) do
    Application.get_env(:curatorian, __MODULE__, []) |> Keyword.get(key, default)
  end
end
