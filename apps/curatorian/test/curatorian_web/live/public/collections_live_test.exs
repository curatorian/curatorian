defmodule CuratorianWeb.Public.CollectionsLiveTest do
  # The shared test database contains pre-existing catalog data; assertions are
  # scoped by unique tokens. `async: false` because the LiveView loads results
  # through `start_async` tasks that need the shared sandbox.
  use CuratorianWeb.ConnCase, async: false

  import Curatorian.CollectionsFixtures
  import Phoenix.LiveViewTest

  describe "URL contract" do
    test "browse renders the page with collections" do
      {col, _, _} = collection_fixture(title: "Zebra Halaman 10001")

      {:ok, view, _html} = live(build_conn(), ~p"/collections")

      assert has_element?(view, "#results-count")
      assert wait_for_content(view, col.title)
    end

    test "q searches and renders the result count" do
      token = "ZebraCari#{System.unique_integer([:positive])}"
      collection_fixture(title: "#{token} Satu")

      {:ok, view, _html} = live(build_conn(), ~p"/collections?q=#{token}")

      assert has_element?(view, "#results-count")
      html = wait_for_content(view, "#{token} Satu")
      assert html =~ "hasil untuk"
    end

    test "searching defaults to list view, browsing to grid view" do
      token = "ZebraView#{System.unique_integer([:positive])}"
      collection_fixture(title: token)

      {:ok, browse_view, _} = live(build_conn(), ~p"/collections")

      assert has_element?(
               browse_view,
               "#view-toggle [phx-value-view='grid'][aria-pressed='true']"
             )

      {:ok, search_view, _} = live(build_conn(), ~p"/collections?q=#{token}")

      assert has_element?(
               search_view,
               "#view-toggle [phx-value-view='list'][aria-pressed='true']"
             )
    end

    test "explicit view param wins over the default" do
      token = "ZebraViewP#{System.unique_integer([:positive])}"
      collection_fixture(title: token)

      {:ok, view, _} = live(build_conn(), ~p"/collections?q=#{token}&view=grid")

      assert has_element?(view, "#view-toggle [phx-value-view='grid'][aria-pressed='true']")
    end

    test "spec param names drive the filters (sector, org, type, lang, prov, city, subject)" do
      token = "ZebraParams#{System.unique_integer([:positive])}"
      {col, unit, resource_class} = collection_fixture(title: token)
      node_profile_fixture(unit, province: "Sumedang Zebra", city: "Sumedang Zebra")
      collection_field_fixture(col, name: "dc:subject", value: "Subjek Zebra #{token}")

      {:ok, view, _html} =
        live(
          build_conn(),
          ~p"/collections?q=#{token}&sector=#{resource_class.glam_type}&org=#{unit.id}&type=book&prov=Sumedang Zebra&city=Sumedang Zebra&subject=Subjek Zebra #{token}"
        )

      assert wait_for_content(view, col.title)
    end

    test "legacy param names still work (glam_type, node_id)" do
      token = "ZebraLegacy#{System.unique_integer([:positive])}"
      {col, unit, resource_class} = collection_fixture(title: token)

      {:ok, view, _html} =
        live(
          build_conn(),
          ~p"/collections?glam_type=#{resource_class.glam_type}&node_id=#{unit.id}"
        )

      assert wait_for_content(view, col.title)
    end

    test "unknown params are ignored, not crashed on" do
      {:ok, view, _html} = live(build_conn(), ~p"/collections?hacker=1&sort=weird&page=abc")

      assert has_element?(view, "#hasil")
    end

    test "out-of-range page clamps to the last page instead of erroring" do
      token = "ZebraPage#{System.unique_integer([:positive])}"
      collection_fixture(title: "#{token} Satu")
      collection_fixture(title: "#{token} Dua")

      {:ok, view, _html} = live(build_conn(), ~p"/collections?q=#{token}&page=999")

      assert has_element?(view, "#results-count")
      assert wait_for_content(view, "#{token} Satu")
    end

    test "URLs with q get noindex,follow; browse stays indexable" do
      token = "ZebraRobots#{System.unique_integer([:positive])}"
      collection_fixture(title: token)

      {:ok, _view, browse_html} = live(build_conn(), ~p"/collections")
      refute browse_html =~ "noindex"

      {:ok, _view, search_html} = live(build_conn(), ~p"/collections?q=#{token}")
      assert search_html =~ "noindex, follow"
    end

    test "sort param is whitelisted; invalid values fall back to the default" do
      {:ok, view, _} = live(build_conn(), ~p"/collections?sort=weird")

      assert has_element?(view, "#sort-select option[selected]", "Terbaru")
    end
  end

  describe "facet panel" do
    test "facet groups with fewer than 2 distinct values are hidden" do
      token = "ZebraFacetHide#{System.unique_integer([:positive])}"
      collection_fixture(title: token)

      {:ok, view, _html} = live(build_conn(), ~p"/collections?q=#{token}")

      # Wait for results first (facets arrive with them via async), then the
      # GLAM facet has exactly one value → hidden (spec §5).
      html = wait_for_content(view, token)

      refute html =~ "Sektor GLAM"
      refute html =~ ~r/>\d+rb</
    end

    test "facet counts never use the banned `rb` abbreviation" do
      {:ok, view, _html} = live(build_conn(), ~p"/collections")

      html = wait_for_content(view, "koleksi")

      refute html =~ ~r/>\d+rb</
    end

    test "facets show options within the filtered set" do
      token = "ZebraFacetVals#{System.unique_integer([:positive])}"
      {col1, unit, _} = collection_fixture(title: "#{token} Satu")
      collection_field_fixture(col1, name: "dc:subject", value: "Subjek #{token}")
      {col2, _, _} = collection_fixture(title: "#{token} Dua")
      collection_field_fixture(col2, name: "dc:subject", value: "Lain #{token}")

      {:ok, view, _html} = live(build_conn(), ~p"/collections?q=#{token}")

      wait_for_content(view, "#{token} Satu")

      assert has_element?(view, "#facet-list-sidebar-units", unit.name)
      html = render(view)
      assert html =~ "Subjek #{token}"
      assert html =~ "Lain #{token}"
    end
  end

  describe "interactions" do
    test "submit_search event patches the URL with q" do
      token = "ZebraSubmit#{System.unique_integer([:positive])}"
      collection_fixture(title: "#{token} Satu")

      {:ok, view, _html} = live(build_conn(), ~p"/collections")

      view
      |> form("#collections-search-form", q: token)
      |> render_submit()

      # Browsing in grid view keeps the explicit grid choice when searching.
      assert_patch(view, ~p"/collections?q=#{token}&view=grid")
    end

    test "set_view event patches the URL" do
      {:ok, view, _html} = live(build_conn(), ~p"/collections")

      render_click(view, "set_view", %{"view" => "list"})

      assert_patch(view, ~p"/collections?view=list")
    end

    test "clear event resets to bare /collections" do
      token = "ZebraClear#{System.unique_integer([:positive])}"
      collection_fixture(title: token)

      {:ok, view, _html} = live(build_conn(), ~p"/collections?q=#{token}")

      render_click(view, "clear", %{})

      assert_patch(view, ~p"/collections")
    end

    test "view toggle keeps the current query" do
      token = "ZebraKeepQ#{System.unique_integer([:positive])}"
      collection_fixture(title: token)

      {:ok, view, _} = live(build_conn(), ~p"/collections?q=#{token}")

      render_click(view, "set_view", %{"view" => "grid"})

      assert_patch(view, ~p"/collections?q=#{token}&view=grid")
    end

    test "change_sort writes non-default sorts and drops defaults" do
      token = "ZebraSort#{System.unique_integer([:positive])}"
      collection_fixture(title: token)

      {:ok, view, _} = live(build_conn(), ~p"/collections?q=#{token}")

      # relevance is the default when searching → param dropped
      render_click(view, "change_sort", %{"sort" => "relevance"})
      assert_patch(view, ~p"/collections?q=#{token}")

      # title is not the default → param written
      render_click(view, "change_sort", %{"sort" => "title"})
      assert_patch(view, ~p"/collections?q=#{token}&sort=title")
    end

    test "filter event toggles a facet value on and off" do
      token = "ZebraToggle#{System.unique_integer([:positive])}"
      collection_fixture(title: token)

      {:ok, view, _} = live(build_conn(), ~p"/collections?q=#{token}")

      render_click(view, "filter", %{"field" => "type", "val" => "book"})
      assert_patch(view, ~p"/collections?q=#{token}&type=book")

      # clicking the active value clears it (checkbox semantics)
      render_click(view, "filter", %{"field" => "type", "val" => "book"})
      assert_patch(view, ~p"/collections?q=#{token}")
    end

    test "clear_filter patches that one param out" do
      token = "ZebraClearOne#{System.unique_integer([:positive])}"
      collection_fixture(title: token)

      {:ok, view, _} = live(build_conn(), ~p"/collections?q=#{token}&type=book")

      render_click(view, "clear_filter", %{"field" => "type"})

      assert_patch(view, ~p"/collections?q=#{token}")
    end
  end

  # Connected navigations load results through start_async; LiveViewTest's
  # render/1 returns before the async result lands, so poll briefly.
  defp wait_for_content(view, text, attempts \\ 100)

  defp wait_for_content(_view, _text, 0), do: flunk("results never rendered")

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
