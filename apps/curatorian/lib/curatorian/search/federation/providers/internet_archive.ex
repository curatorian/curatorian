defmodule Curatorian.Search.Federation.Providers.InternetArchive do
  @moduledoc """
  Internet Archive search provider (spec §9.2).

  * `GET https://archive.org/advancedsearch.php` with `fl[]` fields,
    `rows <= 10`, `output=json`.
  * **Every response field may be a string or a list** — normalized both ways.
  * Lucene special characters in user text are escaped; multi-word input is
    only wrapped in quotes when the user typed quotes.
  * The `access-restricted-item` filter is intentionally NOT applied yet —
    the field semantics are unverified (spec VERIFY note).
  """

  @behaviour Curatorian.Search.Federation.Provider

  alias Curatorian.Search.Federation.Provider
  alias Curatorian.Search.{Query, Result}

  @impl true
  def id, do: :internet_archive

  @impl true
  def label, do: "Internet Archive"

  @impl true
  def kinds, do: [:all, :book, :image, :av]

  @doc "Default upstream base URL (overridable via config/testing stubs)."
  def base_url,
    do:
      Application.get_env(:curatorian, __MODULE__, [])
      |> Keyword.get(:base_url, "https://archive.org")

  @impl true
  def enabled?,
    do: Application.get_env(:curatorian, __MODULE__, []) |> Keyword.get(:enabled, true)

  @impl true
  def rate_limit, do: {1, 2}

  @impl true
  def timeout, do: 5_000

  @fields [
    "identifier",
    "title",
    "creator",
    "year",
    "date",
    "description",
    "mediatype",
    "language"
  ]

  @impl true
  def search(%Query{} = query) do
    client = Req.new(Provider.req_options(__MODULE__))

    params =
      [
        q: lucene_query(query),
        rows: min(query.per_page, 10),
        page: query.page,
        output: "json"
      ] ++ Enum.flat_map(@fields, &["fl[]": &1])

    case Req.get(client, url: "/advancedsearch.php", params: params) do
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

  defp lucene_query(query) do
    mediatype = mediatype_for(query.kind)
    "(#{escape(query.text)}) AND mediatype:#{mediatype}"
  end

  defp mediatype_for(:image), do: "image"
  defp mediatype_for(:av), do: "(audio OR movies)"
  defp mediatype_for(_), do: "texts"

  @doc "Escape Lucene special characters in user text (spec §9.2)."
  def escape(text) do
    text
    |> String.replace("\\", "\\\\")
    |> String.replace(~r/([\+\-\&\|\!\(\)\{\}\[\]\^\"\~\*\?\:\/])/, "\\\\\\1")
  end

  defp page(body, query) do
    response = body["response"] || %{}
    docs = response["docs"] || []

    results =
      docs
      |> Enum.map(&normalize/1)
      |> Enum.reject(&is_nil/1)

    %{results: results, total: response["numFound"], more_url: more_url(query.text)}
  end

  @impl true
  def more_url(text) do
    "https://archive.org/search?query=" <> URI.encode_www_form(text)
  end

  @doc "Normalizer — pure, nil-safe, string-or-list tolerant (spec §9.2)."
  def normalize(doc) when is_map(doc) do
    identifier = doc["identifier"]

    title = first(Provider.to_list(doc["title"]))

    if is_binary(identifier) and identifier != "" and is_binary(title) do
      mediatype = Provider.to_list(doc["mediatype"]) |> List.first("texts")

      Result.new(%{
        source: :internet_archive,
        source_id: identifier,
        title: Provider.plain_text(title),
        url: "https://archive.org/details/#{identifier}",
        creators: Provider.to_list(doc["creator"]),
        year:
          year(first(Provider.to_list(doc["year"]))) ||
            year(first(Provider.to_list(doc["date"]))),
        kind: kind_for(mediatype),
        description: Provider.plain_text(first(Provider.to_list(doc["description"]))),
        thumbnail_url: "https://archive.org/services/img/#{identifier}",
        languages: normalize_languages(Provider.to_list(doc["language"])),
        access: :unknown,
        identifiers: %{ia: [identifier]}
      })
    end
  end

  def normalize(_), do: nil

  defp first([head | _]), do: head
  defp first(_), do: nil

  defp year(y) when is_integer(y), do: y

  defp year(y) when is_binary(y) do
    case Integer.parse(String.slice(y, 0, 4)) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp year(_), do: nil

  defp kind_for("movies"), do: :video
  defp kind_for("audio"), do: :audio
  defp kind_for("image"), do: :image
  defp kind_for(_), do: :book

  # Free-text language values ("Indonesian", "ind", "id") — a soft boost only
  # in the UI; map the obvious ISO forms, leave the rest as-is (§9.2 VERIFY).
  defp normalize_languages(langs) do
    langs
    |> Enum.map(fn
      "ind" -> "id"
      "Indonesian" -> "id"
      other -> other
    end)
    |> Enum.uniq()
  end

  defp retry_after(headers),
    do: Curatorian.Search.Federation.Provider.retry_after_seconds(headers)
end
