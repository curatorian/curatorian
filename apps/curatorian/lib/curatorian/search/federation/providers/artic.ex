defmodule Curatorian.Search.Federation.Providers.Artic do
  @moduledoc """
  Art Institute of Chicago provider — spec §9.8, Tier 3.

  CC0 metadata, no key, no N+1 (search returns full objects):

      GET https://api.artic.edu/api/v1/artworks/search
          ?q=…&fields=…&limit=8&page=1
          &query[term][is_public_domain]=true

  **AIC requires a dedicated `AIC-User-Agent` header** (verified live: 403
  without it, 200 with it), so it is set explicitly in addition to the shared
  UA. Image URLs are built from the response's `config.iiif_url` + `image_id`.
  """

  @behaviour Curatorian.Search.Federation.Provider

  alias Curatorian.Search.Federation.Provider
  alias Curatorian.Search.{Query, Result}

  @fields "id,title,artist_display,date_display,image_id,is_public_domain,thumbnail"

  @impl true
  def id, do: :artic

  @impl true
  def label, do: "Art Institute of Chicago"

  @impl true
  def kinds, do: [:image]

  @impl true
  def auto?, do: false

  @doc "Default upstream base URL (overridable via config/testing stubs)."
  def base_url,
    do:
      Application.get_env(:curatorian, __MODULE__, [])
      |> Keyword.get(:base_url, "https://api.artic.edu")

  @impl true
  def enabled?, do: config(:enabled, true)

  @impl true
  def rate_limit, do: {2, 3}

  @impl true
  def timeout, do: 5_000

  @impl true
  def search(%Query{} = query) do
    client =
      Req.new(
        Provider.req_options(__MODULE__)
        |> Keyword.update(:headers, [aic_header()], fn existing -> [aic_header() | existing] end)
      )

    params = [
      q: query.text,
      fields: @fields,
      limit: min(query.per_page, 10),
      page: query.page,
      "query[term][is_public_domain]": "true"
    ]

    case Req.get(client, url: "/api/v1/artworks/search", params: params) do
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
  def more_url(text), do: "https://www.artic.edu/search?q=" <> URI.encode_www_form(text)

  defp aic_header do
    email = Application.get_env(:curatorian, :contact_email, "admin@curatorian.id")
    {"aic-user-agent", "Curatorian (#{email})"}
  end

  defp page(body, query) do
    iiif = get_in(body, ["config", "iiif_url"]) || "https://www.artic.edu/iiif/2"
    data = body["data"] || []

    results =
      data
      |> Enum.map(&normalize(&1, iiif))
      |> Enum.reject(&is_nil/1)

    %{
      results: results,
      total: get_in(body, ["pagination", "total"]),
      more_url: more_url(query.text)
    }
  end

  @doc "Normalizer — pure, nil-safe (spec §9.8)."
  def normalize(work, iiif_url \\ "https://www.artic.edu/iiif/2")

  def normalize(work, iiif_url) when is_map(work) do
    id = work["id"]
    title = Provider.plain_text(work["title"])
    public_domain = work["is_public_domain"] == true

    if (is_integer(id) or is_binary(id)) and is_binary(title) and title != "" do
      Result.new(%{
        source: :artic,
        source_id: to_string(id),
        title: title,
        url: "https://www.artic.edu/artworks/#{id}",
        creators: creators(work["artist_display"]),
        year: year(work["date_display"]),
        kind: :artwork,
        description: nil,
        thumbnail_url: thumbnail(work["image_id"], iiif_url),
        languages: [],
        access: if(public_domain, do: :open, else: :restricted),
        rights: if(public_domain, do: "Domain publik (CC0)")
      })
    end
  end

  def normalize(_work, _iiif_url), do: nil

  defp creators(nil), do: []

  defp creators(display) when is_binary(display) do
    display
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.take(1)
  end

  defp creators(_), do: []

  defp year(nil), do: nil

  defp year(display) when is_binary(display) do
    case Regex.run(~r/\b(1[0-9]{3}|20[0-9]{2})\b/, display) do
      [_, y] -> String.to_integer(y)
      _ -> nil
    end
  end

  defp year(_), do: nil

  defp thumbnail(nil, _iiif), do: nil

  defp thumbnail(image_id, iiif) when is_binary(image_id) do
    "#{String.trim_trailing(iiif, "/")}/#{image_id}/full/400,/0/default.jpg"
  end

  defp thumbnail(_, _), do: nil

  defp config(key, default) do
    Application.get_env(:curatorian, __MODULE__, []) |> Keyword.get(key, default)
  end
end
