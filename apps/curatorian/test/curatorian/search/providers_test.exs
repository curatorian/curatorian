defmodule Curatorian.Search.ProvidersTest do
  @moduledoc """
  Normalizer + HTTP tests for the Tier-1 providers, against recorded fixtures
  (spec §13). No real network: `Req.Test` stubs are injected via the per-module
  `:plug` config read by `Provider.req_options/1`.
  """

  use ExUnit.Case, async: true

  alias Curatorian.Search.Federation.Provider
  alias Curatorian.Search.Federation.Providers.{InternetArchive, OpenLibrary}
  alias Curatorian.Search.Query

  @ol_fixture Path.expand("../../support/fixtures/search/open_library/search.json", __DIR__)
  @ia_fixture Path.expand("../../support/fixtures/search/internet_archive/search.json", __DIR__)

  defp fixture!(path), do: path |> File.read!() |> Jason.decode!()

  defp with_plug(module, fun) do
    previous = Application.get_env(:curatorian, module, [])

    Application.put_env(
      :curatorian,
      module,
      previous
      |> Keyword.put(:base_url, "https://stub.invalid")
      |> Keyword.put(:plug, {Req.Test, fun})
    )

    on_exit(fn -> Application.put_env(:curatorian, module, previous) end)
  end

  describe "OpenLibrary.normalize/1" do
    test "maps a full doc" do
      [doc | _] = fixture!(@ol_fixture)["docs"]
      result = OpenLibrary.normalize(doc)

      assert result.source == :open_library
      assert result.source_id == "/works/OL12345W"
      assert result.title == "The Rainbow Troops"
      assert result.url == "https://openlibrary.org/works/OL12345W"
      assert result.creators == ["Andrea Hirata"]
      assert result.year == 2005
      assert result.kind == :book
      assert result.thumbnail_url == "https://covers.openlibrary.org/b/id/8231856-M.jpg"
      assert result.access == :open
      assert result.identifiers.ia == ["rainbowtroops0000hira"]
    end

    test "string author_name becomes a list; borrowable when ia but not public scan" do
      result = OpenLibrary.normalize(Enum.at(fixture!(@ol_fixture)["docs"], 1))

      assert result.creators == ["Pramoedya Ananta Toer"]
      assert result.access == :borrowable
      assert result.languages == ["eng", "ind"]
    end

    test "tolerates missing optional fields" do
      result = OpenLibrary.normalize(Enum.at(fixture!(@ol_fixture)["docs"], 2))

      assert result.creators == []
      assert result.year == nil
      assert result.thumbnail_url == nil
      assert result.access == :unknown
    end

    test "returns nil for unusable docs, never raises" do
      assert OpenLibrary.normalize(%{"key" => "/works/OL99999W"}) == nil
      assert OpenLibrary.normalize(%{}) == nil
      assert OpenLibrary.normalize(nil) == nil
      assert OpenLibrary.normalize("nonsense") == nil
      assert OpenLibrary.normalize(%{"title" => "No key"}) == nil
    end

    test "never raises for arbitrary JSON shapes (fuzz)" do
      for shape <- [
            %{},
            [],
            0,
            "x",
            nil,
            %{"key" => 1, "title" => []},
            %{"key" => "/w", "title" => "t", "ia" => 5}
          ] do
        assert OpenLibrary.normalize(shape) == nil or is_struct(OpenLibrary.normalize(shape))
      end
    end
  end

  describe "InternetArchive.normalize/1" do
    test "maps a doc with string fields and strips HTML from description" do
      [doc | _] = fixture!(@ia_fixture)["response"]["docs"]
      result = InternetArchive.normalize(doc)

      assert result.source == :internet_archive
      assert result.source_id == "rainbowtroops0000hira"
      assert result.url == "https://archive.org/details/rainbowtroops0000hira"
      assert result.creators == ["Hirata, Andrea"]
      assert result.year == 2005
      assert result.description == "A novel about ten children & their dreams."
      assert result.thumbnail_url == "https://archive.org/services/img/rainbowtroops0000hira"
      assert result.kind == :book
      assert result.languages == ["id"]
    end

    test "handles list-valued title/creator/year and maps mediatype to kind" do
      result = InternetArchive.normalize(Enum.at(fixture!(@ia_fixture)["response"]["docs"], 1))

      assert result.title == "An Audio Item With A List Title"
      assert result.creators == ["One", "Two"]
      assert result.year == 1999
      assert result.kind == :audio
      assert result.languages == ["eng"]
    end

    test "returns nil for unusable docs" do
      assert InternetArchive.normalize(Enum.at(fixture!(@ia_fixture)["response"]["docs"], 2)) ==
               nil

      assert InternetArchive.normalize(nil) == nil
      assert InternetArchive.normalize(%{"identifier" => "x"}) == nil
    end

    test "escapes Lucene special characters" do
      assert InternetArchive.escape("a+b (c)") == "a\\+b \\(c\\)"
    end
  end

  describe "OpenLibrary.search/1 over Req.Test" do
    test "returns normalized page and more_url" do
      with_plug(OpenLibrary, :open_library_ok)

      Req.Test.stub(:open_library_ok, fn conn ->
        assert conn.request_path == "/search.json"
        assert conn.query_string =~ "q=rainbow"
        Req.Test.json(conn, fixture!(@ol_fixture))
      end)

      assert {:ok, page} = OpenLibrary.search(Query.new("rainbow"))
      assert page.total == 134
      # 4 docs in the fixture: 1 unusable (no title), 1 missing most optional
      # fields but still usable → 3 results.
      assert length(page.results) == 3
      assert page.more_url =~ "openlibrary.org/search?q=rainbow"
    end

    test "429 becomes {:error, {:rate_limited, seconds}}" do
      with_plug(OpenLibrary, :open_library_429)

      Req.Test.stub(:open_library_429, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("retry-after", "17")
        |> Plug.Conn.resp(429, "{}")
      end)

      assert {:error, {:rate_limited, 17}} = OpenLibrary.search(Query.new("x"))
    end

    test "5xx becomes an upstream_status error" do
      with_plug(OpenLibrary, :open_library_500)
      Req.Test.stub(:open_library_500, fn conn -> Plug.Conn.resp(conn, 500, "boom") end)

      assert {:error, {:upstream_status, 500}} = OpenLibrary.search(Query.new("x"))
    end

    test "connection errors never raise" do
      with_plug(OpenLibrary, :open_library_raise)
      Req.Test.stub(:open_library_raise, fn _conn -> raise "connection refused" end)

      assert {:error, _} = OpenLibrary.search(Query.new("x"))
    end
  end

  describe "InternetArchive.search/1 over Req.Test" do
    test "sends mediatype-scoped lucene query and normalizes" do
      with_plug(InternetArchive, :ia_ok)

      Req.Test.stub(:ia_ok, fn conn ->
        assert conn.request_path == "/advancedsearch.php"
        assert conn.query_string =~ "mediatype%3Atexts"
        assert conn.query_string =~ "output=json"
        Req.Test.json(conn, fixture!(@ia_fixture))
      end)

      assert {:ok, page} = InternetArchive.search(Query.new("rainbow"))
      assert page.total == 42
      assert [%{source: :internet_archive} | _] = page.results
    end

    test "image kind switches the mediatype filter" do
      with_plug(InternetArchive, :ia_image)

      Req.Test.stub(:ia_image, fn conn ->
        send(self(), {:query, conn.query_string})
        Req.Test.json(conn, %{"response" => %{"numFound" => 0, "docs" => []}})
      end)

      assert {:ok, %{results: []}} = InternetArchive.search(Query.new("borobudur", kind: :image))
      assert_received {:query, query}
      assert query =~ "mediatype%3Aimage"
    end
  end

  describe "Provider helpers" do
    test "plain_text strips tags/entities and truncates" do
      assert Provider.plain_text("<p>Hello &amp; welcome</p>") == "Hello & welcome"
      assert Provider.plain_text(nil) == nil
      assert Provider.plain_text("   ") == nil
      assert String.length(Provider.plain_text(String.duplicate("a", 500))) == 300
    end

    test "to_list normalizes string-or-list" do
      assert Provider.to_list("a") == ["a"]
      assert Provider.to_list(["a", "b"]) == ["a", "b"]
      assert Provider.to_list(nil) == []
      assert Provider.to_list(123) == []
    end
  end
end
