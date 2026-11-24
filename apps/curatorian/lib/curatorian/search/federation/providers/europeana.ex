defmodule Curatorian.Search.Federation.Providers.Europeana do
  @moduledoc """
  Europeana provider — spec §9.7, Tier 2.

      GET https://api.europeana.eu/record/v2/search.json
          ?wskey=KEY&query=…&rows=8&start=1&reusability=open&profile=minimal

  A free API key is required (`EUROPEANA_API_KEY`); without it the provider is
  disabled and never called. The key travels in the query string, so it must
  never appear in logs or telemetry — errors are mapped to coarse atoms here
  and the URL is never logged.

  Metadata is CC0 but **objects keep per-record rights statements**: `rights`
  is mandatory in the Result and is displayed in the UI.
  """

  @behaviour Curatorian.Search.Federation.Provider

  alias Curatorian.Search.Federation.Provider
  alias Curatorian.Search.{Query, Result}

  @impl true
  def id, do: :europeana

  @impl true
  def label, do: "Europeana"

  @impl true
  def kinds, do: [:image]

  @impl true
  def auto?, do: false

  @doc "Default upstream base URL (overridable via config/testing stubs)."
  def base_url,
    do:
      Application.get_env(:curatorian, __MODULE__, [])
      |> Keyword.get(:base_url, "https://api.europeana.eu")

  @impl true
  def enabled?, do: config(:enabled, true) and not is_nil(api_key())

  @impl true
  def rate_limit, do: {2, 3}

  @impl true
  def timeout, do: 5_000

  def api_key, do: config(:api_key, System.get_env("EUROPEANA_API_KEY"))

  @impl true
  def search(%Query{} = query) do
    if is_nil(api_key()) do
      {:error, :disabled}
    else
      do_search(query)
    end
  end

  defp do_search(query) do
    client = Req.new(Provider.req_options(__MODULE__))

    params = [
      wskey: api_key(),
      query: query.text,
      rows: min(query.per_page, 10),
      start: (query.page - 1) * min(query.per_page, 10) + 1,
      reusability: "open",
      profile: "minimal"
    ]

    case Req.get(client, url: "/record/v2/search.json", params: params) do
      {:ok, %{status: 200, body: raw}} ->
        with {:ok, body} <- Provider.decode_json(raw) do
          {:ok, page(body, query)}
        else
          {:error, :invalid_json} -> {:error, :invalid_json}
        end

      {:ok, %{status: 429, headers: headers}} ->
        {:error, {:rate_limited, Provider.retry_after_seconds(headers)}}

      {:ok, %{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %{status: status}} ->
        {:error, {:upstream_status, status}}

      {:error, %{reason: reason}} ->
        {:error, {:req, reason}}

      {:error, other} ->
        {:error, {:req, other}}
    end
  rescue
    # Never let an exception message carry the wskey-bearing URL.
    _e -> {:error, :request_failed}
  end

  @impl true
  def more_url(text),
    do: "https://www.europeana.eu/en/search?query=" <> URI.encode_www_form(text)

  defp page(body, query) do
    items = body["items"] || []

    results =
      items
      |> Enum.map(&normalize/1)
      |> Enum.reject(&is_nil/1)

    %{results: results, total: body["totalResults"], more_url: more_url(query.text)}
  end

  @doc """
  Normalizer — pure, nil-safe. Written from the documented shape (spec §9.7
  VERIFY note): Europeana was not reachable without a key at implementation
  time, so field names are defensive.
  """
  def normalize(item) when is_map(item) do
    title = first(item["title"])
    url = item["guid"] || item["id"]

    if is_binary(title) and title != "" and is_binary(url) do
      Result.new(%{
        source: :europeana,
        source_id: to_string(item["id"] || url),
        title: Provider.plain_text(title),
        url: url,
        creators: Provider.to_list(item["dcCreator"]),
        year: year(first(item["year"])),
        kind: kind_for(item["type"]),
        description: Provider.plain_text(first(item["dcDescription"])),
        thumbnail_url: first(item["edmPreview"]),
        languages: Provider.to_list(item["language"]) |> Enum.uniq(),
        access: :open,
        # Rights are mandatory for Europeana records (§9.7).
        rights: rights(item),
        extra: %{data_provider: first(item["dataProvider"])}
      })
    end
  end

  def normalize(_), do: nil

  defp rights(item) do
    first(item["rights"]) || first(item["edm:rights"]) || "Lihat hak di sumber"
  end

  defp first(list) when is_list(list), do: List.first(list)
  defp first(value) when is_binary(value), do: value
  defp first(_), do: nil

  defp year(nil), do: nil

  defp year(text) when is_binary(text) do
    case Regex.run(~r/\b(1[0-9]{3}|20[0-9]{2})\b/, text) do
      [_, y] -> String.to_integer(y)
      _ -> nil
    end
  end

  defp year(_), do: nil

  defp kind_for("IMAGE"), do: :image
  defp kind_for("TEXT"), do: :book
  defp kind_for("SOUND"), do: :audio
  defp kind_for("VIDEO"), do: :video
  defp kind_for(_), do: :artwork

  defp config(key, default) do
    Application.get_env(:curatorian, __MODULE__, []) |> Keyword.get(key, default)
  end
end
