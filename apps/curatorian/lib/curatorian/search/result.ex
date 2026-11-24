defmodule Curatorian.Search.Result do
  @moduledoc """
  Unified search result across sources (spec §7.1).

  Local Curatorian results and external-provider results both map onto this
  struct so cards share components. External results always keep
  `source: :curatorian | :open_library | :internet_archive | ...`.
  """

  @enforce_keys [:source, :source_id, :title, :url]

  defstruct [
    :source,
    :source_id,
    :title,
    :url,
    :creators,
    :year,
    :kind,
    :description,
    :thumbnail_url,
    :languages,
    :access,
    :rights,
    :read_url,
    :identifiers,
    :extra
  ]

  @type access :: :open | :borrowable | :restricted | :unknown
  @type kind :: :book | :article | :audio | :video | :image | :artwork | :archive | :other

  @type t :: %__MODULE__{
          source: atom(),
          source_id: String.t(),
          title: String.t(),
          url: String.t(),
          creators: [String.t()],
          year: non_neg_integer() | nil,
          kind: kind(),
          description: String.t() | nil,
          thumbnail_url: String.t() | nil,
          languages: [String.t()],
          access: access(),
          rights: String.t() | nil,
          read_url: String.t() | nil,
          identifiers: map(),
          extra: map()
        }

  def new(attrs) do
    %__MODULE__{
      source: attrs.source,
      source_id: attrs.source_id,
      title: attrs.title,
      url: attrs.url,
      creators: Map.get(attrs, :creators, []),
      year: Map.get(attrs, :year),
      kind: Map.get(attrs, :kind, :other),
      description: Map.get(attrs, :description),
      thumbnail_url: Map.get(attrs, :thumbnail_url),
      languages: Map.get(attrs, :languages, []),
      access: Map.get(attrs, :access, :unknown),
      rights: Map.get(attrs, :rights),
      read_url: Map.get(attrs, :read_url),
      identifiers: Map.get(attrs, :identifiers, %{}),
      extra: Map.get(attrs, :extra, %{})
    }
  end
end
