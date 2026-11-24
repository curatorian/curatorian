defmodule CuratorianWeb.UserForgotPasswordLiveTest do
  use CuratorianWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Curatorian.AccountsFixtures

  # Voile auth tables are written through Voile.Repo — assertions must use the
  # same repo (same sandbox connection) to see in-test writes.
  alias Voile.Repo
  alias Voile.Schema.Accounts.UserToken

  setup do
    %{user: user_fixture()}
  end

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/users/reset_password")

      assert html =~ "Lupa kata sandi?"
      assert has_element?(lv, ~s|a[href="#{~p"/login"}"]|, "Masuk di sini")
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())

      result = live(conn, ~p"/users/reset_password")
      assert {:error, {:live_redirect, %{to: "/foyer"}}} = result
    end
  end

  describe "Reset link" do
    test "sends a new reset password token", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset_password")

      {:ok, conn} =
        lv
        |> form("#forgot-password-form", user: %{"email" => user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/login")

      # One neutral message for every outcome — never reveal whether the
      # account exists.
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Jika email tersebut terdaftar"

      assert token = Repo.get_by!(UserToken, user_id: user.id)
      assert token.context == "reset_password"
    end

    test "does not send reset password token if email is unknown", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset_password")

      {:ok, conn} =
        lv
        |> form("#forgot-password-form", user: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/login")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Jika email tersebut terdaftar"

      assert Repo.all(UserToken) == []
    end
  end
end
