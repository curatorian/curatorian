defmodule Curatorian.Search.Federation.Router do
  @moduledoc """
  Which providers serve which query kind (spec §8.5).

  * `kind=all` fans out to the text-oriented Tier 1/2 providers only, and only
    those whose `auto?/0` allows it: OpenAlex opts out while its daily budget
    is degraded/exhausted (§8.7.7), and the art/photo sources (Commons, AIC,
    Cleveland, Europeana) always opt out so book results are not crowded out.
    The UI shows the top 3 per provider in this view.
  * `kind=book` → Open Library, Internet Archive, Gutendex, DOAB, Wikisource.
  * `kind=article` → OpenAlex.
  * `kind=image` → Wikimedia Commons, Art Institute of Chicago, Cleveland,
    Europeana, plus Internet Archive images.
  * `kind=av` → Internet Archive audio/movies.
  """

  alias Curatorian.Search.Federation.Providers.{
    Artic,
    Cleveland,
    Commons,
    Doab,
    Europeana,
    Gutendex,
    InternetArchive,
    OpenAlex,
    OpenLibrary,
    Wikisource
  }

  @providers %{
    open_library: OpenLibrary,
    internet_archive: InternetArchive,
    open_alex: OpenAlex,
    gutendex: Gutendex,
    doab: Doab,
    wikisource: Wikisource,
    commons: Commons,
    artic: Artic,
    cleveland: Cleveland,
    europeana: Europeana
  }

  @kind_map %{
    all: [OpenLibrary, InternetArchive, OpenAlex, Gutendex, Doab, Wikisource],
    book: [OpenLibrary, InternetArchive, Gutendex, Doab, Wikisource],
    article: [OpenAlex],
    image: [Commons, Artic, Cleveland, Europeana, InternetArchive],
    av: [InternetArchive]
  }

  @display_kind %{
    open_library: :book,
    internet_archive: :book,
    open_alex: :article,
    gutendex: :book,
    doab: :book,
    wikisource: :book,
    commons: :image,
    artic: :image,
    cleveland: :image,
    europeana: :image
  }

  @doc "Enabled providers for a kind; `:all` additionally applies each provider's `auto?/0`."
  def providers_for(:all) do
    @kind_map
    |> Map.fetch!(:all)
    |> Enum.filter(& &1.enabled?())
    |> Enum.filter(&auto_allowed?/1)
  end

  def providers_for(kind) do
    @kind_map
    |> Map.get(kind, [])
    |> Enum.filter(& &1.enabled?())
  end

  def provider(id) do
    case Map.fetch(@providers, id) do
      {:ok, module} -> if module.enabled?(), do: module, else: nil
      :error -> nil
    end
  end

  def provider_label(id) do
    case Map.fetch(@providers, id) do
      {:ok, module} -> module.label()
      :error -> humanize(id)
    end
  end

  @doc "The kind tab a provider's \"see more\" link should switch to."
  def display_kind(id), do: Map.get(@display_kind, id, :all)

  def all_provider_ids, do: Map.keys(@providers)

  defp auto_allowed?(module) do
    if function_exported?(module, :auto?, 0), do: module.auto?(), else: true
  end

  defp humanize(id), do: id |> to_string() |> String.replace("_", " ") |> String.capitalize()
end
