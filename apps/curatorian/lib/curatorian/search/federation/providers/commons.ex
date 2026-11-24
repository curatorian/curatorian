defmodule Curatorian.Search.Federation.Providers.Commons do
  @moduledoc """
  Wikimedia Commons provider — spec §9.6, Tier 2.

  Free-licensed images/media via the MediaWiki API:

      GET https://commons.wikimedia.org/w/api.php
          ?action=query&generator=search&gsrnamespace=6&gsrsearch=…
          &gsrlimit=8&prop=imageinfo&iiprop=url|extmetadata|mime
          &iiurlwidth=320&format=json&formatversion=2

  Only image MIME types are kept. `extmetadata.LicenseShortName.value` becomes
  `rights`; `extmetadata.Artist.value` contains HTML and is stripped.
  Wikimedia requires an identifying User-Agent (shared UA satisfies it).
  """

  @behaviour Curatorian.Search.Federation.Provider

  alias Curatorian.Search.Federation.Provider
  alias Curatorian.Search.{Query, Result}

  @image_mimes ~w(image/jpeg image/png image/gif image/tiff image/webp image/svg+xml)

  @impl true
  def id, do: :commons

  @impl true
  def label, do: "Wikimedia Commons"

  @impl true
  def kinds, do: [:image]

  @doc """
  Art/photo sources stay out of the `all` view (they would crowd the book
  results); they fire on the "Gambar & karya seni" tab only.
  """
  @impl true
  def auto?, do: false

  @doc "Default upstream base URL (overridable via config/testing stubs)."
  def base_url,
    do:
      Application.get_env(:curatorian, __MODULE__, [])
      |> Keyword.get(:base_url, "https://commons.wikimedia.org")

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
      generator: "search",
      gsrnamespace: "6",
      gsrsearch: query.text,
      gsrlimit: min(query.per_page, 10),
      gsroffset: (query.page - 1) * min(query.per_page, 10),
      prop: "imageinfo",
      iiprop: "url|extmetadata|mime",
      iiurlwidth: "320",
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
    do: "https://commons.wikimedia.org/w/index.php?search=" <> URI.encode_www_form(text)

  defp page(body, query) do
    pages = get_in(body, ["query", "pages"]) || []

    results =
      pages
      |> Enum.map(&normalize/1)
      |> Enum.reject(&is_nil/1)

    # The generator API does not report a total; nil means "unknown".
    %{results: results, total: nil, more_url: more_url(query.text)}
  end

  @doc "Normalizer — pure, nil-safe; keeps image MIME types only (spec §9.6)."
  def normalize(item) when is_map(item) do
    image_info = (item["imageinfo"] || []) |> List.first() || %{}
    mime = image_info["mime"]
    title = item["title"]

    if is_binary(title) and mime in @image_mimes do
      metadata = image_info["extmetadata"] || %{}

      Result.new(%{
        source: :commons,
        source_id: to_string(item["pageid"] || title),
        title: Provider.plain_text(String.replace_prefix(title, "File:", "")),
        url: file_url(title),
        creators: creators(metadata),
        year: year(metadata),
        kind: :image,
        description: Provider.plain_text(meta_value(metadata, "ImageDescription")),
        thumbnail_url: image_info["thumburl"] || image_info["url"],
        languages: [],
        access: :open,
        rights: meta_value(metadata, "LicenseShortName")
      })
    end
  end

  def normalize(_), do: nil

  defp creators(metadata) do
    case Provider.plain_text(meta_value(metadata, "Artist")) do
      nil -> []
      artist -> [artist]
    end
  end

  defp year(metadata) do
    case Provider.plain_text(meta_value(metadata, "DateTimeOriginal")) do
      nil ->
        nil

      text ->
        case Regex.run(~r/\b(1[0-9]{3}|20[0-9]{2})\b/, text) do
          [_, year] -> String.to_integer(year)
          _ -> nil
        end
    end
  end

  defp meta_value(metadata, key) do
    case metadata[key] do
      %{"value" => value} when is_binary(value) -> value
      _ -> nil
    end
  end

  @doc "Commons file page URL."
  def file_url(title), do: "https://commons.wikimedia.org/wiki/" <> Provider.wiki_encode(title)

  defp config(key, default) do
    Application.get_env(:curatorian, __MODULE__, []) |> Keyword.get(key, default)
  end
end
