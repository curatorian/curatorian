defmodule Curatorian.Search.Federation.Provider do
  @moduledoc """
  Behaviour every external search provider implements (spec §7.3).

  Providers build requests with `Req` (`retry: false` — the Federator owns
  retries/caching), never raise on missing fields, and strip any HTML from
  text fields before returning results.
  """

  alias Curatorian.Search.{Query, Result}

  @type page :: %{
          required(:results) => [Result.t()],
          optional(:total) => non_neg_integer() | nil,
          required(:more_url) => String.t()
        }

  @callback id() :: atom()
  @callback label() :: String.t()
  @callback kinds() :: [Query.kind()]
  @callback enabled?() :: boolean()
  @callback rate_limit() :: {max_per_second :: pos_integer(), burst :: pos_integer()}
  @callback timeout() :: pos_integer()
  @callback search(Query.t()) :: {:ok, page()} | {:error, term()}

  # Optional: whether the provider may auto-fire in the `all` view (§8.7.7 —
  # OpenAlex returns false while its daily budget is degraded/exhausted).
  @callback auto?() :: boolean()
  # Optional: the provider's own website search URL for "see all" links.
  @callback more_url(String.t()) :: String.t()

  @optional_callbacks auto?: 0, more_url: 1

  @doc "User-Agent every provider must send (identifying, with contact)."
  def user_agent do
    email = Application.get_env(:curatorian, :contact_email, "admin@curatorian.id")
    "Curatorian/1.0 (+https://curatorian.id; mailto:#{email})"
  end

  @doc """
  Req client options shared by all providers. Reads an optional per-module
  `:plug` config (test stubs) and per-module `:base_url` override.
  """
  def req_options(module) do
    opts = [
      retry: false,
      receive_timeout: module.timeout(),
      # Connect failures (dead providers) fail fast instead of stalling on the
      # OS default; the provider's block shows "belum merespons" either way.
      connect_options: [timeout: 2_500],
      max_redirects: 2,
      user_agent: user_agent(),
      # Providers decode JSON manually so a non-JSON error body still yields a
      # clean {:error, {:upstream_status, _}} instead of a decode exception.
      decode_body: false
    ]

    opts
    |> maybe_put(:base_url, base_url(module))
    |> maybe_put(:plug, plug(module))
  end

  @doc """
  Base URL for a provider: explicit config wins, then the provider's own
  `base_url/0` default (so production works without extra config).
  """
  def base_url(module) do
    configured = Application.get_env(:curatorian, module, []) |> Keyword.get(:base_url)

    configured ||
      (function_exported?(module, :base_url, 0) && module.base_url()) ||
      nil
  end

  def plug(module) do
    Application.get_env(:curatorian, module, []) |> Keyword.get(:plug)
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  @doc "Attach an optional Req `:plug` (used by tests)."
  def maybe_put_plug(opts, nil), do: opts
  def maybe_put_plug(opts, plug), do: Keyword.put(opts, :plug, plug)

  @doc "Strip tags, decode entities, collapse whitespace — plain text only (§11)."
  def plain_text(nil), do: nil

  def plain_text(text) when is_binary(text) do
    text
    |> String.replace(~r/<[^>]*>/, " ")
    |> unescape_entities()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> case do
      "" -> nil
      trimmed -> String.slice(trimmed, 0, 300)
    end
  end

  def plain_text(_), do: nil

  defp unescape_entities(text) do
    text
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("\u201C", "\"")
    |> String.replace("\u201D", "\"")
    |> String.replace("&#39;", "'")
    |> String.replace("\u2019", "'")
    |> String.replace("&nbsp;", " ")
  end

  @doc """
  Read `Retry-After` from Req response headers (map or keyword list, value may
  be a string or a list). Returns seconds, default 30.
  """
  def retry_after_seconds(headers) do
    raw =
      cond do
        is_map(headers) ->
          headers["retry-after"] || headers["Retry-After"]

        is_list(headers) ->
          match?({_, _}, List.keyfind(headers, "retry-after", 0)) &&
            elem(List.keyfind(headers, "retry-after", 0), 1)

        true ->
          nil
      end

    value =
      case raw do
        [v | _] -> v
        v -> v
      end

    case Integer.parse(to_string(value)) do
      {n, _} when n > 0 -> n
      _ -> 30
    end
  end

  @doc "Decode a raw JSON body."
  def decode_json(raw) when is_binary(raw) do
    case Jason.decode(raw) do
      {:ok, body} -> {:ok, body}
      {:error, _} -> {:error, :invalid_json}
    end
  end

  def decode_json(body) when is_map(body), do: {:ok, body}
  def decode_json(_), do: {:error, :invalid_json}

  @doc """
  Encode a MediaWiki page title for a `/wiki/` URL: spaces become underscores,
  and characters that are legal and readable in wiki URLs (`, : ( ) ! ' /`)
  stay unescaped. Subpage slashes therefore survive.
  """
  def wiki_encode(title) when is_binary(title) do
    title
    |> String.replace(" ", "_")
    |> URI.encode(fn c -> c in [?/, ?,, ?:, ?(, ?), ?!, ?'] or URI.char_unreserved?(c) end)
  end

  @doc "Convert string-or-list fields (archive.org) to lists; nil-safe."
  def to_list(nil), do: []

  def to_list(value) when is_list(value) do
    Enum.flat_map(value, fn
      v when is_binary(v) -> [v]
      _ -> []
    end)
  end

  def to_list(value) when is_binary(value), do: [value]
  def to_list(_), do: []
end
