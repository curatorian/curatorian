defmodule Curatorian.Search.ExternalContractTest do
  @moduledoc """
  Real-network contract tests (spec §13). **Excluded by default**; run manually
  to detect upstream schema drift:

      mix test --include external test/curatorian/search/external_contract_test.exs

  These assert only on *shape and invariants* (a non-empty title, an absolute
  URL, a parsed year, a licence label) — never on specific records, which
  change over time. Failures here mean a provider's response schema moved and
  its normalizer needs attention.
  """

  use ExUnit.Case, async: false

  alias Curatorian.Search.Federation.Providers.{
    Artic,
    Cleveland,
    Commons,
    Europeana,
    Gutendex,
    InternetArchive,
    OpenAlex,
    OpenLibrary,
    Wikisource
  }

  alias Curatorian.Search.Query

  @moduletag :external
  @moduletag timeout: 60_000

  setup_all do
    for table <- [
          :curatorian_search_cache,
          :curatorian_search_breaker,
          :curatorian_search_limiter,
          :curatorian_search_cooldown,
          :curatorian_search_claims
        ] do
      :ets.delete_all_objects(table)
    end

    :ok
  end

  # Providers run against their real upstreams here: no :base_url / :plug.
  defp real!(module) do
    previous = Application.get_env(:curatorian, module, [])

    Application.put_env(
      :curatorian,
      module,
      previous |> Keyword.drop([:base_url, :plug])
    )

    on_exit(fn -> Application.put_env(:curatorian, module, previous) end)
  end

  describe "Open Library" do
    @tag :external
    test "search returns usable book records" do
      real!(OpenLibrary)

      assert {:ok, page} = OpenLibrary.search(Query.new("laskar pelangi"))
      assert page.results != []

      result = hd(page.results)
      assert is_binary(result.title) and result.title != ""
      assert String.starts_with?(result.url, "https://openlibrary.org/")
      assert result.kind == :book
    end
  end

  describe "Internet Archive" do
    @tag :external
    test "search returns usable records with identifiers" do
      real!(InternetArchive)

      assert {:ok, page} = InternetArchive.search(Query.new("laskar pelangi"))
      assert page.results != []

      result = hd(page.results)
      assert String.starts_with?(result.url, "https://archive.org/details/")
      assert result.identifiers[:ia] != []
    end
  end

  describe "Wikisource" do
    @tag :external
    test "search returns Indonesian texts with clean snippets" do
      real!(Wikisource)

      assert {:ok, page} = Wikisource.search(Query.new("pramoedya"))
      assert page.results != []

      result = hd(page.results)
      assert String.starts_with?(result.url, "https://id.wikisource.org/wiki/")
      refute to_string(result.description) =~ "<span"
      assert result.access == :open
    end
  end

  describe "Wikimedia Commons" do
    @tag :external
    test "search returns image records with licence labels" do
      real!(Commons)

      assert {:ok, page} = Commons.search(Query.new("borobudur", kind: :image))
      assert page.results != []

      result = hd(page.results)
      assert result.kind == :image
      assert is_binary(result.thumbnail_url)
      assert is_binary(result.rights) and result.rights != ""
    end
  end

  describe "Art Institute of Chicago" do
    @tag :external
    test "search returns public-domain artworks with IIIF thumbnails" do
      real!(Artic)

      assert {:ok, page} = Artic.search(Query.new("indonesia", kind: :image))
      assert page.results != []

      result = hd(page.results)
      assert result.kind == :artwork
      assert String.starts_with?(result.url, "https://www.artic.edu/artworks/")
      assert result.access == :open
      assert result.thumbnail_url =~ "/full/400,/0/default.jpg"
    end
  end

  describe "Cleveland Museum of Art" do
    @tag :external
    test "search returns CC0 works with web images" do
      real!(Cleveland)

      assert {:ok, page} = Cleveland.search(Query.new("indonesia", kind: :image))
      assert page.results != []

      result = hd(page.results)
      assert result.kind == :artwork
      assert result.rights == "CC0"
      assert is_binary(result.thumbnail_url)
    end
  end

  describe "OpenAlex" do
    @tag :external
    test "search returns scholarly works with DOIs when a key is configured" do
      if OpenAlex.api_key() do
        real!(OpenAlex)

        assert {:ok, page} = OpenAlex.search(Query.new("open access", kind: :article))
        assert page.results != []

        result = hd(page.results)
        assert result.kind == :article
        assert is_binary(result.title)
        assert result.identifiers[:doi] == nil or is_binary(result.identifiers[:doi])
      else
        # Without a key the provider is disabled by design (§9.3).
        refute OpenAlex.enabled?()
      end
    end
  end

  describe "Gutendex" do
    @tag :external
    test "search returns public-domain ebooks when the service is up" do
      real!(Gutendex)

      case Gutendex.search(Query.new("pride and prejudice")) do
        {:ok, page} ->
          assert page.results != []

          result = hd(page.results)
          assert String.starts_with?(result.url, "https://www.gutenberg.org/ebooks/")
          assert result.access == :open

        # Community-run service (§9.4): a transport failure means "down", not
        # "schema drift" — report it without failing the suite.
        {:error, {:req, _} = reason} ->
          IO.warn("Gutendex unreachable, contract unverified this run: #{inspect(reason)}")

        {:error, :timeout} ->
          IO.warn("Gutendex timed out, contract unverified this run")

        {:error, other} ->
          flunk("Gutendex contract changed: #{inspect(other)}")
      end
    end
  end

  describe "Europeana" do
    @tag :external
    test "search returns records with mandatory rights when a key is configured" do
      if Europeana.api_key() do
        real!(Europeana)

        assert {:ok, page} = Europeana.search(Query.new("borobudur", kind: :image))
        assert page.results != []

        result = hd(page.results)
        assert is_binary(result.rights) and result.rights != ""
      else
        refute Europeana.enabled?()
      end
    end
  end
end
