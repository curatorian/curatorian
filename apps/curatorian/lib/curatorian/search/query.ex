defmodule Curatorian.Search.Query do
  @moduledoc """
  Normalized external-search query (spec §7.2).

  Text is NFKC-normalized, trimmed and whitespace-collapsed; the normalized
  form also keys the federation cache (spec §8.3.1).
  """

  @enforce_keys [:text]
  defstruct [:text, :page, :per_page, :languages, :kind, :open_only]

  @type kind :: :all | :book | :article | :image | :av
  @type t :: %__MODULE__{
          text: String.t(),
          page: pos_integer(),
          per_page: pos_integer(),
          languages: [String.t()],
          kind: kind(),
          open_only: boolean()
        }

  @default_per_page 8
  @max_page 5

  def new(text, opts \\ []) when is_binary(text) do
    %__MODULE__{
      text: normalize_text(text),
      page: opts |> Keyword.get(:page, 1) |> clamp_page(),
      per_page: opts |> Keyword.get(:per_page, @default_per_page) |> clamp_per_page(),
      languages: Keyword.get(opts, :languages, []),
      kind: Keyword.get(opts, :kind, :all),
      open_only: Keyword.get(opts, :open_only, true)
    }
  end

  @doc "Cache-key form: NFKC, downcase, trim, collapse whitespace (spec §8.3.1)."
  def normalize_text(text) when is_binary(text) do
    text
    |> String.normalize(:nfkc)
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end

  defp clamp_page(page) when is_integer(page) and page >= 1, do: min(page, @max_page)
  defp clamp_page(_), do: 1

  defp clamp_per_page(n) when is_integer(n) and n >= 1 and n <= 10, do: n
  defp clamp_per_page(_), do: @default_per_page
end
