defmodule Curatorian.Search.Federation.Providers.OpenLibrary do
  @moduledoc """
  Open Library search provider (spec §9.1).

  * `GET https://openlibrary.org/search.json` with an explicit `fields` list
    (never `fields=*` — the schema is not guaranteed stable).
  * No per-result follow-up requests (docs explicitly discourage them).
  * Identifying User-Agent is what unlocks 3 req/s; our limiter stays at 2.
  """

  @behaviour Curatorian.Search.Federation.Provider

  alias Curatorian.Search.Federation.Provider
  alias Curatorian.Search.{Query, Result}

  @impl true
  def id, do: :open_library

  @impl true
  def label, do: "Open Library"

  @impl true
  def kinds, do: [:all, :book]

  @doc "Default upstream base URL (overridable via config/testing stubs)."
  def base_url,
    do:
      Application.get_env(:curatorian, __MODULE__, [])
      |> Keyword.get(:base_url, "https://openlibrary.org")

  @impl true
  def enabled?,
    do: Application.get_env(:curatorian, __MODULE__, []) |> Keyword.get(:enabled, true)

  @impl true
  def rate_limit, do: {2, 3}

  @impl true
  def timeout, do: 4_000

  @fields "key,title,author_name,first_publish_year,cover_i,ia,public_scan_b,language,edition_count,has_fulltext"

  @impl true
  def search(%Query{} = query) do
    client = Req.new(Provider.req_options(__MODULE__))

    params =
      [
        q: query.text,
        fields: @fields,
        limit: query.per_page,
        page: query.page
      ]
      |> maybe_lang(query.languages)

    case Req.get(client, url: "/search.json", params: params) do
      {:ok, %{status: 200, body: raw}} ->
        with {:ok, body} <- Provider.decode_json(raw) do
          {:ok, page(body, query)}
        else
          {:error, :invalid_json} -> {:error, :invalid_json}
        end

      {:ok, %{status: 429, headers: headers}} ->
        {:error, {:rate_limited, retry_after(headers)}}

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

  defp page(body, query) do
    docs = body["docs"] || []

    results =
      docs
      |> Enum.map(&normalize/1)
      |> Enum.reject(&is_nil/1)

    %{results: results, total: body["numFound"], more_url: more_url(query.text)}
  end

  @impl true
  def more_url(text) do
    "https://openlibrary.org/search?q=" <> URI.encode_www_form(text)
  end

  @doc "Normalizer — pure, nil-safe, never raises (spec §7.3)."
  def normalize(doc) when is_map(doc) do
    key = doc["key"]

    if is_binary(key) and is_binary(doc["title"]) and doc["title"] != "" do
      ia_ids = Provider.to_list(doc["ia"])

      access =
        cond do
          doc["public_scan_b"] == true -> :open
          ia_ids != [] -> :borrowable
          true -> :unknown
        end

      Result.new(%{
        source: :open_library,
        source_id: key,
        title: Provider.plain_text(doc["title"]) || String.slice(to_string(doc["title"]), 0, 200),
        url: "https://openlibrary.org" <> key,
        creators: Provider.to_list(doc["author_name"]),
        year: int_or_nil(doc["first_publish_year"]),
        kind: :book,
        description: nil,
        thumbnail_url: thumbnail(doc["cover_i"]),
        languages: Provider.to_list(doc["language"]),
        access: access,
        identifiers: %{ia: ia_ids}
      })
    end
  end

  def normalize(_), do: nil

  defp thumbnail(nil), do: nil
  defp thumbnail(cover_i), do: "https://covers.openlibrary.org/b/id/#{cover_i}-M.jpg"

  defp int_or_nil(n) when is_integer(n), do: n
  defp int_or_nil(_), do: nil

  defp maybe_lang(params, []), do: params
  defp maybe_lang(params, langs), do: Keyword.put(params, :lang, Enum.join(langs, ","))

  defp retry_after(headers), do: Provider.retry_after_seconds(headers)
end
