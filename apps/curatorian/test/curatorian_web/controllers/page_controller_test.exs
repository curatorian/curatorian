defmodule CuratorianWeb.PageControllerTest do
  use CuratorianWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)
    assert response =~ "Curatorian"
    # Flagship cross-node search bar is present on the hero
    assert response =~ "hero-search"
  end
end
