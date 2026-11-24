defmodule Curatorian.Search.ProvidersC4Test do
  @moduledoc """
  C4 providers — Wikisource, Wikimedia Commons, Art Institute of Chicago,
  Cleveland Museum of Art, Europeana (spec §9.6–§9.8).

  Normalizer fixtures were captured from live responses on 2026-11-24; the
  Europeana normalizer is written from the documented shape and marked as
  unverified (no key at implementation time).
  """

  use ExUnit.Case, async: false

  alias Curatorian.Search.Federation.Provider
  alias Curatorian.Search.Federation.Providers.{Artic, Cleveland, Commons, Europeana, Wikisource}
  alias Curatorian.Search.Query

  @wikisource Path.expand("../../support/fixtures/search/wikisource/search.json", __DIR__)
  @commons Path.expand("../../support/fixtures/search/commons/search.json", __DIR__)
  @artic Path.expand("../../support/fixtures/search/artic/search.json", __DIR__)
  @cleveland Path.expand("../../support/fixtures/search/cleveland/search.json", __DIR__)

  defp fixture!(path), do: path |> File.read!() |> Jason.decode!()

  defp set_config(module, opts) do
    previous = Application.get_env(:curatorian, module, [])
    Application.put_env(:curatorian, module, Keyword.merge(previous, opts))
    on_exit(fn -> Application.put_env(:curatorian, module, previous) end)
  end

  describe "Wikisource" do
    test "normalizes search hits and strips snippet HTML" do
      [item | _] = get_in(fixture!(@wikisource), ["query", "search"])
      result = Wikisource.normalize(item)

      assert result.source == :wikisource
      assert result.source_id == "4850"
      assert result.title == "Tan Malaka, Sejak Agustus Itu"
      assert result.url == "https://id.wikisource.org/wiki/Tan_Malaka,_Sejak_Agustus_Itu"
      assert result.kind == :book
      assert result.access == :open
      assert result.languages == ["id"]
      # Snippet HTML is stripped, entities decoded.
      refute result.description =~ "<span"
      assert result.description =~ "Pramoedya"
    end

    test "page_url keeps subpage slashes and encodes spaces" do
      assert Wikisource.page_url("Aku Ini Binatang Jalang/Bibliografi") ==
               "https://id.wikisource.org/wiki/Aku_Ini_Binatang_Jalang/Bibliografi"
    end

    test "tolerates unusable items" do
      assert Wikisource.normalize(%{}) == nil
      assert Wikisource.normalize(nil) == nil
    end

    test "search reads totalhits and builds more_url" do
      set_config(Wikisource, base_url: "https://stub.invalid", plug: {Req.Test, :ws_ok})

      Req.Test.stub(:ws_ok, fn conn ->
        assert conn.request_path == "/w/api.php"
        assert conn.query_string =~ "srsearch=pramoedya"
        Req.Test.json(conn, fixture!(@wikisource))
      end)

      assert {:ok, page} = Wikisource.search(Query.new("pramoedya"))
      assert page.total == 4
      assert length(page.results) == 3
      assert page.more_url =~ "id.wikisource.org"
    end
  end

  describe "Commons" do
    test "normalizes image pages with licence and stripped artist HTML" do
      [page | _] = get_in(fixture!(@commons), ["query", "pages"])
      result = Commons.normalize(page)

      assert result.source == :commons
      assert result.kind == :image
      assert result.title == "Borobudur-Nothwest-view.jpg"
      assert result.url =~ "commons.wikimedia.org/wiki/File:"
      assert result.access == :open
      assert result.rights in ["Public domain", "CC BY-SA 3.0", "CC BY-SA 4.0"]
      assert result.thumbnail_url =~ "thumb.wikimedia.org"
      # Artist metadata is HTML in the API; must be plain text.
      refute Enum.any?(result.creators, &(&1 =~ "<a"))
    end

    test "keeps image MIME types only" do
      audio = %{
        "title" => "File:Song.ogg",
        "pageid" => 1,
        "imageinfo" => [%{"mime" => "audio/ogg", "thumburl" => "https://x/y"}]
      }

      assert Commons.normalize(audio) == nil
    end

    test "search sends the generator query and namespace 6" do
      set_config(Commons, base_url: "https://stub.invalid", plug: {Req.Test, :commons_ok})

      Req.Test.stub(:commons_ok, fn conn ->
        assert conn.query_string =~ "gsrnamespace=6"
        assert conn.query_string =~ "iiprop=url%7Cextmetadata%7Cmime"
        Req.Test.json(conn, fixture!(@commons))
      end)

      assert {:ok, page} = Commons.search(Query.new("borobudur", kind: :image))
      assert length(page.results) == 3
    end

    test "does not auto-fire in the all view" do
      refute Commons.auto?()
    end
  end

  describe "Art Institute of Chicago" do
    test "normalizes works with IIIF images and public-domain access" do
      body = fixture!(@artic)
      iiif = get_in(body, ["config", "iiif_url"])
      [work | _] = body["data"]

      result = Artic.normalize(work, iiif)

      assert result.source == :artic
      assert result.kind == :artwork
      assert result.title == "Young Princesses Perform \"Serempi\" dance, Indonesia"
      assert result.url == "https://www.artic.edu/artworks/189353"
      assert result.year == 1949
      assert result.creators == ["Henri Cartier-Bresson"]
      # Fixture record is not public domain → restricted, no CC0 claim.
      assert result.access == :restricted
      assert result.rights == nil

      assert result.thumbnail_url ==
               "https://www.artic.edu/iiif/2/74c523e6-e841-ac1a-decb-aabb0b37a281/full/400,/0/default.jpg"
    end

    test "public-domain works are open with a CC0 rights label" do
      result = Artic.normalize(%{"id" => 1, "title" => "Cat", "is_public_domain" => true})
      assert result.access == :open
      assert result.rights =~ "CC0"
    end

    test "search sends the AIC-User-Agent header and the public-domain filter" do
      set_config(Artic, base_url: "https://stub.invalid", plug: {Req.Test, :aic_ok})

      Req.Test.stub(:aic_ok, fn conn ->
        assert conn.request_path == "/api/v1/artworks/search"
        assert Plug.Conn.get_req_header(conn, "aic-user-agent") != []
        assert conn.query_string =~ "is_public_domain"
        Req.Test.json(conn, fixture!(@artic))
      end)

      assert {:ok, page} = Artic.search(Query.new("indonesia", kind: :image))
      assert page.total == 133_375
      assert length(page.results) == 3
    end

    test "returns nil for unusable works" do
      assert Artic.normalize(%{}) == nil
      assert Artic.normalize(%{"id" => 1}) == nil
      assert Artic.normalize(nil) == nil
    end
  end

  describe "Cleveland Museum of Art" do
    test "normalizes CC0 works with web images" do
      body = fixture!(@cleveland)
      [work | _] = body["data"]

      result = Cleveland.normalize(work)

      assert result.source == :cleveland
      assert result.kind == :artwork
      assert result.title == "Architectural Sculpture: Face of Time (Kala-mukha)"
      assert result.url == "https://clevelandart.org/art/1975.104"
      assert result.year == 1100
      assert result.access == :open
      assert result.rights == "CC0"
      assert result.thumbnail_url =~ "openaccess-cdn.clevelandart.org"
      assert result.extra.culture == "Indonesia, Eastern Java"
    end

    test "search passes cc0/has_image filters and reads info.total" do
      set_config(Cleveland, base_url: "https://stub.invalid", plug: {Req.Test, :cle_ok})

      Req.Test.stub(:cle_ok, fn conn ->
        assert conn.request_path == "/api/artworks/"
        assert conn.query_string =~ "cc0=1"
        assert conn.query_string =~ "has_image=1"
        Req.Test.json(conn, fixture!(@cleveland))
      end)

      assert {:ok, page} = Cleveland.search(Query.new("indonesia", kind: :image))
      assert page.total == 75
      assert length(page.results) == 3
    end

    test "tolerates unusable works" do
      assert Cleveland.normalize(%{"id" => 1}) == nil
      assert Cleveland.normalize(nil) == nil
    end
  end

  describe "Europeana" do
    test "is disabled without a key" do
      set_config(Europeana, api_key: nil, enabled: true, base_url: "https://stub.invalid")
      refute Europeana.enabled?()
      assert {:error, :disabled} = Europeana.search(Query.new("cat"))
    end

    test "normalizes the documented item shape and always carries rights" do
      set_config(Europeana, api_key: "test-key")

      item = %{
        "id" => "/90402/item1",
        "guid" => "https://www.europeana.eu/item/90402/item1",
        "title" => ["Borobudur"],
        "dcCreator" => ["Anonymous"],
        "year" => ["c. 1890"],
        "edmPreview" => ["https://images.europeana.eu/preview.jpg"],
        "rights" => ["http://creativecommons.org/publicdomain/mark/1.0/"],
        "dataProvider" => ["Rijksmuseum"],
        "type" => "IMAGE",
        "language" => ["nl"]
      }

      result = Europeana.normalize(item)

      assert result.source == :europeana
      assert result.title == "Borobudur"
      assert result.kind == :image
      assert result.year == 1890
      assert result.thumbnail_url =~ "europeana.eu"
      assert result.rights =~ "creativecommons.org"
      assert result.extra.data_provider == "Rijksmuseum"
    end

    test "rights falls back to a visible label when the record omits it" do
      result = Europeana.normalize(%{"id" => "x", "guid" => "https://e/x", "title" => ["T"]})
      assert result.rights == "Lihat hak di sumber"
    end

    test "never leaks the key in error atoms" do
      set_config(Europeana,
        api_key: "secret-key",
        base_url: "https://stub.invalid",
        plug: {Req.Test, :euro_401}
      )

      Req.Test.stub(:euro_401, fn conn -> Plug.Conn.resp(conn, 401, "{}") end)

      assert {:error, :unauthorized} = Europeana.search(Query.new("x"))
    end

    test "returns nil for unusable items" do
      assert Europeana.normalize(%{}) == nil
      assert Europeana.normalize(nil) == nil
    end
  end

  describe "Router (C4)" do
    test "the image tab fans out to the art/photo sources" do
      ids = Curatorian.Search.Federation.Router.providers_for(:image) |> Enum.map(& &1.id())

      assert :commons in ids
      assert :artic in ids
      assert :cleveland in ids
      assert :internet_archive in ids
    end

    test "art sources never auto-fire in the all view" do
      ids = Curatorian.Search.Federation.Router.providers_for(:all) |> Enum.map(& &1.id())

      refute :commons in ids
      refute :artic in ids
      refute :cleveland in ids
      refute :europeana in ids
      assert :open_library in ids
    end

    test "Wikisource joins the book and all views" do
      assert :wikisource in Enum.map(
               Curatorian.Search.Federation.Router.providers_for(:book),
               & &1.id()
             )

      assert :wikisource in Enum.map(
               Curatorian.Search.Federation.Router.providers_for(:all),
               & &1.id()
             )
    end

    test "every provider maps to a display kind tab" do
      for id <- Curatorian.Search.Federation.Router.all_provider_ids() do
        assert Curatorian.Search.Federation.Router.display_kind(id) in [
                 :book,
                 :article,
                 :image,
                 :av,
                 :all
               ]
      end
    end
  end

  describe "Provider helpers" do
    test "decode_json handles a list body (DOAB) and objects" do
      assert {:ok, []} = Provider.decode_json("[]")
      assert {:ok, %{"a" => 1}} = Provider.decode_json("{\"a\":1}")
    end
  end
end
