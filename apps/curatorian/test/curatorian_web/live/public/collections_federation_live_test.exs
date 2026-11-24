defmodule CuratorianWeb.Public.CollectionsFederationLiveTest do
  @moduledoc """
  End-to-end federation behaviour on /collections (spec D4, §8.1, §10).

  Both Tier-1 providers are stubbed at the HTTP layer via `Req.Test`, so these
  tests exercise the real Router → Federator → provider → normalizer path.
  """

  use CuratorianWeb.ConnCase, async: false

  import Curatorian.CollectionsFixtures
  import Phoenix.LiveViewTest

  alias Curatorian.Search.Federation.Budget

  alias Curatorian.Search.Federation.Providers.{
    Doab,
    Gutendex,
    InternetArchive,
    OpenAlex,
    OpenLibrary
  }

  @ol_fixture Path.expand("../../../support/fixtures/search/open_library/search.json", __DIR__)
  @ia_fixture Path.expand(
                "../../../support/fixtures/search/internet_archive/search.json",
                __DIR__
              )

  setup do
    for table <- [
          :curatorian_search_cache,
          :curatorian_search_breaker,
          :curatorian_search_limiter,
          :curatorian_search_cooldown,
          :curatorian_search_claims
        ] do
      :ets.delete_all_objects(table)
    end

    ol = @ol_fixture |> File.read!() |> Jason.decode!()
    ia = @ia_fixture |> File.read!() |> Jason.decode!()

    openalex =
      Path.expand("../../../support/fixtures/search/open_alex/search.json", __DIR__)
      |> File.read!()
      |> Jason.decode!()

    Req.Test.stub(:collections_ext, fn conn ->
      case conn.request_path do
        "/search.json" ->
          Req.Test.json(conn, ol)

        "/advancedsearch.php" ->
          Req.Test.json(conn, ia)

        "/works" ->
          Req.Test.json(conn, openalex)

        "/books" ->
          Req.Test.json(conn, %{"count" => 0, "results" => []})

        "/rest/search" ->
          Req.Test.json(conn, [])

        "/rate-limit" ->
          Req.Test.json(conn, %{})

        "/w/api.php" ->
          Req.Test.json(conn, %{"query" => %{"pages" => []}})

        "/api/v1/artworks/search" ->
          Req.Test.json(conn, %{"data" => [], "pagination" => %{"total" => 0}})

        "/api/artworks/" ->
          Req.Test.json(conn, %{"data" => [], "info" => %{"total" => 0}})
      end
    end)

    for module <- [
          OpenLibrary,
          InternetArchive,
          Gutendex,
          Doab,
          Wikisource,
          Commons,
          Artic,
          Cleveland,
          Europeana
        ] do
      previous = Application.get_env(:curatorian, module, [])

      Application.put_env(
        :curatorian,
        module,
        previous
        |> Keyword.put(:base_url, "https://stub.invalid")
        |> Keyword.put(:plug, {Req.Test, :collections_ext})
      )

      on_exit(fn -> Application.put_env(:curatorian, module, previous) end)
    end

    # OpenAlex requires a key to be enabled at all.
    previous_oa = Application.get_env(:curatorian, OpenAlex, [])

    Application.put_env(
      :curatorian,
      OpenAlex,
      previous_oa
      |> Keyword.put(:api_key, "test-key")
      |> Keyword.put(:enabled, true)
      |> Keyword.put(:base_url, "https://stub.invalid")
      |> Keyword.put(:plug, {Req.Test, :collections_ext})
    )

    on_exit(fn -> Application.put_env(:curatorian, OpenAlex, previous_oa) end)

    Budget.clear()
    on_exit(fn -> Budget.clear() end)

    :ok
  end

  describe "D4 trigger rules" do
    test "the static (disconnected) render never contains external results" do
      token = "ZebraExt#{System.unique_integer([:positive])}"
      collection_fixture(title: "#{token} Satu")

      html = build_conn() |> get(~p"/collections?q=#{token}") |> html_response(200)

      refute html =~ "Dari sumber terbuka lain"
      refute html =~ "Open Library"
    end

    test "facet-only patches do not fan out" do
      token = "ZebraFacetOnly#{System.unique_integer([:positive])}"
      collection_fixture(title: token)

      {:ok, view, _html} = live(build_conn(), ~p"/collections?q=#{token}")
      wait_for_content(view, token)

      render_click(view, "filter", %{"field" => "type", "val" => "book"})
      wait_for_content(view, "type=book")

      refute render(view) =~ "Dari sumber terbuka lain"
    end

    test "ext=0 disables external sources entirely" do
      token = "ZebraNoExt#{System.unique_integer([:positive])}"
      collection_fixture(title: token)

      {:ok, view, _html} = live(build_conn(), ~p"/collections?q=#{token}&ext=0")
      wait_for_content(view, token)

      view |> form("#collections-search-form", q: token) |> render_submit()
      wait_for_content(view, token)

      refute render(view) =~ "Dari sumber terbuka lain"
    end

    test "an explicit submit fans out and renders both provider shelves" do
      # A local match keeps the section in its normal (below local) placement.
      collection_fixture(title: "Rainbow Lokal #{System.unique_integer([:positive])}")

      {:ok, view, _html} = live(build_conn(), ~p"/collections")
      wait_for_content(view, "koleksi")

      view |> form("#collections-search-form", q: "rainbow") |> render_submit()

      html = wait_for_content(view, "Dari sumber terbuka lain")

      # Provider blocks, external note and third-party results are rendered.
      assert html =~ "Open Library"
      assert html =~ "Internet Archive"
      assert html =~ "bukan koleksi Curatorian"
      assert html =~ "The Rainbow Troops"
      assert html =~ "Akses terbuka"

      # External links open in a new tab with rel=noopener noreferrer.
      assert html =~ ~s(rel="noopener noreferrer")
      # The fixture's OL and IA records share an IA identifier → one card.
      # Dedupe is deterministic: Open Library wins the survivor slot (§8.4).
      assert html =~ "openlibrary.org/works/OL12345W"
      # Internet Archive keeps its non-duplicate result in its own shelf.
      assert html =~ "An Audio Item With A List Title"
    end

    test "external results are deduplicated across providers" do
      {:ok, view, _html} = live(build_conn(), ~p"/collections")
      wait_for_content(view, "koleksi")

      view |> form("#collections-search-form", q: "rainbow") |> render_submit()
      html = wait_for_content(view, "hasil ganda antar-sumber disembunyikan")

      assert html =~ "1 hasil ganda"
    end

    test "promotes the external section above local results when local is empty" do
      {:ok, view, _html} = live(build_conn(), ~p"/collections?q=zzzznothinglocal")
      wait_for_content(view, "Tidak ada koleksi untuk")

      view |> form("#collections-search-form", q: "zzzznothinglocal") |> render_submit()

      html = wait_for_content(view, "Tidak ditemukan di Curatorian")
      # Promoted placement: the heading itself becomes the explanation (§6A.7).
      assert html =~ "Hasil dari sumber terbuka lain"
      assert html =~ "Open Library"
      assert html =~ "The Rainbow Troops"
    end
  end

  describe "C3 providers and budget guard" do
    test "kind=article renders OpenAlex results as compact rows" do
      {:ok, view, _html} = live(build_conn(), ~p"/collections?kind=article")
      wait_for_content(view, "koleksi")

      view |> form("#collections-search-form", q: "commons") |> render_submit()

      html = wait_for_content(view, "Open Access and the Commons")
      assert html =~ "OpenAlex"
      # Text-only source: metadata line + DOI, no cover shelf required.
      assert html =~ "Journal of Open Knowledge"
      assert html =~ "DOI 10.1234/abc.2023"
    end

    test "an exhausted budget renders the until-reset state with an out-link" do
      Budget.mark_exhausted(DateTime.utc_now() |> DateTime.add(6, :hour) |> DateTime.to_unix())

      {:ok, view, _html} = live(build_conn(), ~p"/collections?kind=article")
      wait_for_content(view, "koleksi")

      view |> form("#collections-search-form", q: "commons") |> render_submit()

      html = wait_for_content(view, "dibatasi sampai")
      assert html =~ "WIB"
      assert html =~ "Cari langsung di OpenAlex"
    end

    test "the all view shows the top 3 per provider with a see-more link" do
      docs =
        for i <- 1..5 do
          %{
            "key" => "/works/TOP#{i}",
            "title" => "Top Result #{i}",
            "author_name" => ["Author #{i}"],
            "ia" => []
          }
        end

      Req.Test.stub(:collections_ext, fn conn ->
        empty_ia = %{"response" => %{"numFound" => 0, "docs" => []}}

        case conn.request_path do
          "/search.json" -> Req.Test.json(conn, %{"numFound" => 5, "docs" => docs})
          "/advancedsearch.php" -> Req.Test.json(conn, empty_ia)
          "/works" -> Req.Test.json(conn, %{"meta" => %{"count" => 0}, "results" => []})
          "/books" -> Req.Test.json(conn, %{"count" => 0, "results" => []})
          "/rest/search" -> Req.Test.json(conn, [])
        end
      end)

      {:ok, view, _html} = live(build_conn(), ~p"/collections")
      wait_for_content(view, "koleksi")

      view |> form("#collections-search-form", q: "top") |> render_submit()

      html = wait_for_content(view, "Lihat lebih banyak dari Open Library")
      assert html =~ "Top Result 1"
      assert html =~ "Top Result 3"
      refute html =~ "Top Result 4"
    end

    test "a degraded budget hides OpenAlex from the all view and offers the article tab" do
      Budget.mark_exhausted(DateTime.utc_now() |> DateTime.add(6, :hour) |> DateTime.to_unix())

      {:ok, view, _html} = live(build_conn(), ~p"/collections")
      wait_for_content(view, "koleksi")

      view |> form("#collections-search-form", q: "rainbow") |> render_submit()

      html = wait_for_content(view, "Pencarian artikel ilmiah dibatasi sementara")
      assert html =~ "Cari artikel ilmiah"
      refute html =~ "Open Access and the Commons"
    end
  end

  describe "image tab (C4 sources)" do
    test "the image tab queries the art/photo sources and renders their shelves" do
      aic = %{
        "pagination" => %{"total" => 2},
        "config" => %{"iiif_url" => "https://www.artic.edu/iiif/2"},
        "data" => [
          %{
            "id" => 146_556,
            "title" => "God Ganesha, Remover of Obstacles",
            "artist_display" => "Indonesia\nJavanese",
            "date_display" => "900s",
            "image_id" => "d7a33a29-6ffd-a7a5-261b-52eae41d8c81",
            "is_public_domain" => true
          }
        ]
      }

      Req.Test.stub(:collections_ext, fn conn ->
        case conn.request_path do
          "/api/v1/artworks/search" ->
            Req.Test.json(conn, aic)

          "/api/artworks/" ->
            Req.Test.json(conn, %{
              "info" => %{"total" => 1},
              "data" => [
                %{
                  "id" => 148_070,
                  "title" => "Architectural Sculpture: Face of Time (Kala-mukha)",
                  "url" => "https://clevelandart.org/art/1975.104",
                  "creation_date_earliest" => 1100,
                  "share_license_status" => "CC0",
                  "images" => %{
                    "web" => %{"url" => "https://openaccess-cdn.clevelandart.org/x.jpg"}
                  }
                }
              ]
            })

          "/w/api.php" ->
            Req.Test.json(conn, %{
              "query" => %{
                "pages" => [
                  %{
                    "title" => "File:Borobudur.jpg",
                    "pageid" => 1,
                    "imageinfo" => [
                      %{
                        "mime" => "image/jpeg",
                        "thumburl" => "https://thumb.wikimedia.org/x.jpg",
                        "extmetadata" => %{"LicenseShortName" => %{"value" => "CC BY-SA 4.0"}}
                      }
                    ]
                  }
                ]
              }
            })

          _ ->
            Req.Test.json(conn, %{"response" => %{"numFound" => 0, "docs" => []}})
        end
      end)

      {:ok, view, _html} = live(build_conn(), ~p"/collections?kind=image")
      wait_for_content(view, "koleksi")

      view |> form("#collections-search-form", q: "indonesia") |> render_submit()

      # Providers resolve progressively — wait for the last one before
      # asserting across all of them.
      wait_for_content(view, "God Ganesha")
      wait_for_content(view, "Face of Time (Kala-mukha)")
      html = wait_for_content(view, "CC BY-SA 4.0")

      assert html =~ "Art Institute of Chicago"
      assert html =~ "Cleveland Museum of Art"
      assert html =~ "Wikimedia Commons"
      assert html =~ "Domain publik (CC0)"
      # External links open in a new tab.
      assert html =~ ~s(rel="noopener noreferrer")
    end

    test "the image tab does not query book-only providers" do
      Req.Test.stub(:collections_ext, fn conn ->
        send(self(), {:hit, conn.request_path})
        Req.Test.json(conn, %{"response" => %{"numFound" => 0, "docs" => []}})
      end)

      {:ok, view, _html} = live(build_conn(), ~p"/collections?kind=image")
      wait_for_content(view, "koleksi")

      view |> form("#collections-search-form", q: "borobudur") |> render_submit()
      wait_for_content(view, "Dari sumber terbuka lain")

      paths = collect_hits([])
      refute "/search.json" in paths
      refute "/works" in paths
    end
  end

  describe "provider failure states" do
    test "a failing provider shows its own status block; the other still renders" do
      Req.Test.stub(:collections_ext, fn conn ->
        case conn.request_path do
          "/search.json" ->
            Plug.Conn.resp(conn, 500, "boom")

          "/advancedsearch.php" ->
            Req.Test.json(conn, @ia_fixture |> File.read!() |> Jason.decode!())
        end
      end)

      {:ok, view, _html} = live(build_conn(), ~p"/collections")
      wait_for_content(view, "koleksi")

      view |> form("#collections-search-form", q: "rainbow") |> render_submit()

      html = wait_for_content(view, "belum merespons")
      assert html =~ "Open Library belum merespons"
      assert html =~ "Coba lagi"
      # Internet Archive still rendered its shelf.
      assert html =~ "The Rainbow Troops"
    end

    test "a 429 shows the limited state with retry and an out-link" do
      Req.Test.stub(:collections_ext, fn conn ->
        case conn.request_path do
          "/search.json" ->
            conn
            |> Plug.Conn.put_resp_header("retry-after", "12")
            |> Plug.Conn.resp(429, "{}")

          "/advancedsearch.php" ->
            Req.Test.json(conn, @ia_fixture |> File.read!() |> Jason.decode!())
        end
      end)

      {:ok, view, _html} = live(build_conn(), ~p"/collections")
      wait_for_content(view, "koleksi")

      view |> form("#collections-search-form", q: "rainbow") |> render_submit()

      html = wait_for_content(view, "sedang dibatasi sementara")
      assert html =~ "Coba lagi dalam"
      assert html =~ "Cari langsung di Open Library"
    end
  end

  defp collect_hits(acc) do
    receive do
      {:hit, path} -> collect_hits([path | acc])
    after
      0 -> acc
    end
  end

  # Connected renders load asynchronously; poll briefly.
  defp wait_for_content(view, text, attempts \\ 150)

  defp wait_for_content(_view, _text, 0), do: flunk("content never rendered")

  defp wait_for_content(view, text, attempts) do
    html = render(view)

    if html =~ text do
      html
    else
      Process.sleep(20)
      wait_for_content(view, text, attempts - 1)
    end
  end
end
