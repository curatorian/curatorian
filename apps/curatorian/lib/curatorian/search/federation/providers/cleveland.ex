defmodule Curatorian.Search.Federation.Providers.Cleveland do
  @moduledoc """
  Cleveland Museum of Art provider — spec §9.8, Tier 3.

  CC0 metadata and images, no key, no N+1:

      GET https://openaccess-api.clevelandart.org/api/artworks/
          ?q=…&cc0=1&has_image=1&limit=8&skip=0

  Total is in `info.total`. Images at `images.web.url`; licence in
  `share_license_status` (CC0 for the open-access set).
  """

  @behaviour Curatorian.Search.Federation.Provider

  alias Curatorian.Search.Federation.Provider
  alias Curatorian.Search.{Query, Result}

  @impl true
  def id, do: :cleveland

  @impl true
  def label, do: "Cleveland Museum of Art"

  @impl true
  def kinds, do: [:image]

  @impl true
  def auto?, do: false

  @doc "Default upstream base URL (overridable via config/testing stubs)."
  def base_url,
    do:
      Application.get_env(:curatorian, __MODULE__, [])
      |> Keyword.get(:base_url, "https://openaccess-api.clevelandart.org")

  @impl true
  def enabled?, do: config(:enabled, true)

  @impl true
  def rate_limit, do: {2, 3}

  @impl true
  def timeout, do: 5_000

  @impl true
  def search(%Query{} = query) do
    client = Req.new(Provider.req_options(__MODULE__))

    params = [
      q: query.text,
      cc0: "1",
      has_image: "1",
      limit: min(query.per_page, 10),
      skip: (query.page - 1) * min(query.per_page, 10)
    ]

    case Req.get(client, url: "/api/artworks/", params: params) do
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
    do: "https://www.clevelandart.org/art/collection/search?search=" <> URI.encode_www_form(text)

  defp page(body, query) do
    data = body["data"] || []

    results =
      data
      |> Enum.map(&normalize/1)
      |> Enum.reject(&is_nil/1)

    %{results: results, total: get_in(body, ["info", "total"]), more_url: more_url(query.text)}
  end

  @doc "Normalizer — pure, nil-safe (spec §9.8)."
  def normalize(work) when is_map(work) do
    id = work["id"]
    title = Provider.plain_text(work["title"])

    if (is_integer(id) or is_binary(id)) and is_binary(title) and title != "" do
      cc0 = work["share_license_status"] == "CC0"

      Result.new(%{
        source: :cleveland,
        source_id: to_string(id),
        title: title,
        url: work["url"] || "https://www.clevelandart.org/art/#{work["accession_number"] || id}",
        creators: creators(work["creators"]),
        year: year(work["creation_date_earliest"] || work["creation_date"]),
        kind: :artwork,
        description: Provider.plain_text(work["description"]),
        thumbnail_url: get_in(work, ["images", "web", "url"]),
        languages: [],
        access: if(cc0, do: :open, else: :restricted),
        rights: if(cc0, do: "CC0"),
        extra: %{culture: List.first(work["culture"] || []), medium: work["technique"]}
      })
    end
  end

  def normalize(_), do: nil

  defp creators(creators) when is_list(creators) do
    creators
    |> Enum.map(fn
      %{"description" => d} when is_binary(d) -> d
      %{"name" => n} when is_binary(n) -> n
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp creators(_), do: []

  defp year(y) when is_integer(y), do: y

  defp year(text) when is_binary(text) do
    case Regex.run(~r/\b(1[0-9]{3}|20[0-9]{2})\b/, text) do
      [_, y] -> String.to_integer(y)
      _ -> nil
    end
  end

  defp year(_), do: nil

  defp config(key, default) do
    Application.get_env(:curatorian, __MODULE__, []) |> Keyword.get(key, default)
  end
end
