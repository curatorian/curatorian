defmodule Curatorian.Search.Federation.Providers.OpenAlex do
  @moduledoc """
  OpenAlex scholarly-works provider (spec §9.3).

  * A free API key is **required** in 2026; without one the provider is
    disabled (no silent budget burn).
  * Auth via `Authorization: Bearer` (never `?api_key=`, to keep keys out of
    logs).
  * Budgets are USD/day — the `Budget` guard polls `/rate-limit`, marks the
    provider degraded below 25% and stops it below 10% (or on a
    daily-budget 429). Never hardcode budget numbers.
  * Abstracts are skipped in MVP (they arrive as an inverted index).
  """

  @behaviour Curatorian.Search.Federation.Provider

  alias Curatorian.Search.Federation.{Budget, Provider}
  alias Curatorian.Search.{Query, Result}

  @select "id,doi,display_name,publication_year,type,authorships,primary_location,open_access,language"

  @impl true
  def id, do: :open_alex

  @impl true
  def label, do: "OpenAlex"

  @impl true
  def kinds, do: [:all, :article]

  @doc "Default upstream base URL (overridable via config/testing stubs)."
  def base_url, do: config(:base_url, "https://api.openalex.org")

  @impl true
  def enabled?, do: config(:enabled, true) and not is_nil(api_key())

  @impl true
  def rate_limit, do: {3, 3}

  @impl true
  def timeout, do: 5_000

  @doc "Auto-fire in the `all` view only while the daily budget is healthy (§8.7.7)."
  @impl true
  def auto?, do: Budget.status() in [:ok, :unavailable]

  def api_key, do: config(:api_key, System.get_env("OPENALEX_API_KEY"))

  @impl true
  def search(%Query{} = query) do
    cond do
      is_nil(api_key()) ->
        {:error, :disabled}

      Budget.status() == :exhausted ->
        {:error, {:budget, Budget.resets_at()}}

      true ->
        do_search(query)
    end
  end

  def budget_req_options do
    [
      base_url: config(:base_url, "https://api.openalex.org"),
      headers: [{"authorization", "Bearer #{api_key()}"}],
      retry: false,
      receive_timeout: timeout(),
      decode_body: false
    ]
    |> Provider.maybe_put_plug(config(:plug, nil))
  end

  defp do_search(query) do
    opts = budget_req_options()
    client = Req.new(opts)

    params = [
      search: query.text,
      select: @select,
      per_page: min(query.per_page, 10),
      page: query.page
    ]

    params =
      if query.open_only, do: Keyword.put(params, :filter, "open_access.is_oa:true"), else: params

    params = maybe_language(params, query.languages)

    case Req.get(client, url: "/works", params: params) do
      {:ok, %{status: 200, body: raw}} ->
        case Provider.decode_json(raw) do
          {:ok, body} -> {:ok, page(body, query)}
          {:error, :invalid_json} -> {:error, :invalid_json}
        end

      {:ok, %{status: 429, headers: headers, body: raw}} ->
        handle_429(headers, raw)

      {:ok, %{status: 403}} ->
        # Key present but rejected/quotas disabled for it.
        {:error, :unauthorized}

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

  defp handle_429(headers, raw) do
    body =
      case Provider.decode_json(raw) do
        {:ok, decoded} -> decoded
        _ -> %{}
      end

    message = inspect(body) |> String.downcase()

    if String.contains?(message, "daily") or String.contains?(message, "budget") do
      resets_at = Budget.resets_at()
      Budget.mark_exhausted(resets_at)
      {:error, {:budget, resets_at}}
    else
      {:error, {:rate_limited, Provider.retry_after_seconds(headers)}}
    end
  end

  defp page(body, query) do
    works = body["results"] || []

    results =
      works
      |> Enum.map(&normalize/1)
      |> Enum.reject(&is_nil/1)

    %{
      results: results,
      total: get_in(body, ["meta", "count"]),
      more_url: more_url(query.text)
    }
  end

  @impl true
  def more_url(text), do: "https://openalex.org/works?search=" <> URI.encode_www_form(text)

  @doc "Normalizer — pure, nil-safe (spec §9.3)."
  def normalize(work) when is_map(work) do
    title = Provider.plain_text(work["display_name"])
    doi = normalize_doi(work["doi"])

    if is_binary(title) and title != "" do
      oa = work["open_access"] || %{}
      location = work["primary_location"] || %{}
      source = location["source"] || %{}

      url =
        first_url([oa["oa_url"], location["landing_page_url"], work["doi"], work["id"]])

      Result.new(%{
        source: :open_alex,
        source_id: to_string(work["id"] || doi || title),
        title: title,
        url: url,
        creators: creators(work["authorships"]),
        year: year(work["publication_year"]),
        kind: kind_for(work["type"]),
        description: nil,
        thumbnail_url: nil,
        languages: Provider.to_list(work["language"]) |> Enum.uniq(),
        access: if(oa["is_oa"] == true, do: :open, else: :restricted),
        identifiers: %{doi: doi},
        extra: %{
          venue: source["display_name"],
          also_at_source: []
        }
      })
    end
  end

  def normalize(_), do: nil

  defp creators(authorships) when is_list(authorships) do
    authorships
    |> Enum.map(fn
      %{"author" => %{"display_name" => name}} when is_binary(name) -> name
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp creators(_), do: []

  defp normalize_doi(nil), do: nil

  defp normalize_doi(doi) when is_binary(doi) do
    doi
    |> String.replace_prefix("https://doi.org/", "")
    |> String.replace_prefix("http://dx.doi.org/", "")
    |> String.downcase()
  end

  defp normalize_doi(_), do: nil

  defp first_url(urls) do
    Enum.find(urls, fn u -> is_binary(u) and u != "" end)
  end

  defp year(y) when is_integer(y), do: y
  defp year(_), do: nil

  defp kind_for("book"), do: :book
  defp kind_for("book-chapter"), do: :article
  defp kind_for("article"), do: :article
  defp kind_for(_), do: :article

  defp maybe_language(params, []), do: params

  defp maybe_language(params, [iso | _]) when is_binary(iso) do
    Keyword.update(params, :filter, "language:#{iso}", fn existing ->
      existing <> ",language:#{iso}"
    end)
  end

  defp maybe_language(params, _), do: params

  defp config(key, default) do
    Application.get_env(:curatorian, __MODULE__, []) |> Keyword.get(key, default)
  end
end
