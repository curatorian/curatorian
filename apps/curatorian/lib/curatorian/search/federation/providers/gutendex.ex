defmodule Curatorian.Search.Federation.Providers.Gutendex do
  @moduledoc """
  Gutendex (Project Gutenberg) provider — spec §9.4, Tier 2.

  Caveat documented in code: `gutendex.com` is a **community-run service, not
  operated by Project Gutenberg**. Expect occasional downtime; the circuit
  breaker matters here. Page size is server-defined (historically 32) — we
  take the first 8 from page 1 and never hardcode the page size.
  """

  @behaviour Curatorian.Search.Federation.Provider

  alias Curatorian.Search.Federation.Provider
  alias Curatorian.Search.{Query, Result}

  @take 8

  @impl true
  def id, do: :gutendex

  @impl true
  def label, do: "Project Gutenberg"

  @impl true
  def kinds, do: [:all, :book]

  @doc "Default upstream base URL (overridable via config/testing stubs)."
  def base_url, do: config(:base_url, "https://gutendex.com")

  @impl true
  def enabled?, do: config(:enabled, true)

  @impl true
  def rate_limit, do: {1, 2}

  @impl true
  def timeout, do: 3_000

  @impl true
  def search(%Query{} = query) do
    client = Req.new(Provider.req_options(__MODULE__))

    params =
      [search: query.text, page: query.page]
      |> maybe_languages(query.languages)

    case Req.get(client, url: "/books", params: params) do
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
    do: "https://www.gutenberg.org/ebooks/search/?query=" <> URI.encode_www_form(text)

  defp page(body, query) do
    results =
      (body["results"] || [])
      |> Enum.take(@take)
      |> Enum.map(&normalize/1)
      |> Enum.reject(&is_nil/1)

    %{results: results, total: body["count"], more_url: more_url(query.text)}
  end

  @doc "Normalizer — pure, nil-safe (spec §9.4)."
  def normalize(book) when is_map(book) do
    id = book["id"]
    title = Provider.plain_text(book["title"])
    formats = book["formats"] || %{}

    if (is_integer(id) or is_binary(id)) and is_binary(title) do
      Result.new(%{
        source: :gutendex,
        source_id: to_string(id),
        title: title,
        url: "https://www.gutenberg.org/ebooks/#{id}",
        creators: creators(book["authors"]),
        year: nil,
        kind: :book,
        description: nil,
        thumbnail_url: format(formats, "image/jpeg"),
        languages: Provider.to_list(book["languages"]) |> Enum.uniq(),
        access: :open,
        rights: "Domain publik (Project Gutenberg)",
        read_url: format(formats, "text/html") || format(formats, "application/epub+zip"),
        identifiers: %{gutenberg: [to_string(id)]}
      })
    end
  end

  def normalize(_), do: nil

  defp creators(authors) when is_list(authors) do
    authors
    |> Enum.map(fn
      %{"name" => name} when is_binary(name) -> name
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp creators(_), do: []

  defp format(formats, mime) when is_map(formats) do
    case formats[mime] do
      url when is_binary(url) and url != "" -> url
      _ -> nil
    end
  end

  defp format(_formats, _mime), do: nil

  defp maybe_languages(params, []), do: params

  defp maybe_languages(params, languages) do
    Keyword.put(params, :languages, Enum.join(languages, ","))
  end

  defp config(key, default) do
    Application.get_env(:curatorian, __MODULE__, []) |> Keyword.get(key, default)
  end
end
