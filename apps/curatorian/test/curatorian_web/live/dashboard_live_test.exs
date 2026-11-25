defmodule CuratorianWeb.DashboardLiveTest do
  @moduledoc """
  `/dashboard` is the entry point that explains the two workspaces (Foyer and
  Atrium) instead of silently sending everyone to Atrium's dashboard.
  """

  use CuratorianWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Curatorian.AccountsFixtures

  describe "/dashboard" do
    test "requires login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/dashboard")
    end

    test "shows both workspaces with working entry buttons", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, lv, html} = live(conn, ~p"/dashboard")

      assert html =~ "Foyer"
      assert html =~ "Atrium"
      assert has_element?(lv, ~s(a[href="/foyer"]))
      assert has_element?(lv, ~s(a[href="http://localhost:4001/dashboard"]))
    end
  end
end
