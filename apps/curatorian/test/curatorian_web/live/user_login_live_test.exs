defmodule CuratorianWeb.UserLoginLiveTest do
  use CuratorianWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Curatorian.AccountsFixtures

  describe "Log in page" do
    test "renders log in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/login")

      assert html =~ "Sign in"
      assert html =~ "Create an account"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())

      {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/login")
    end
  end

  describe "user login" do
    test "redirects if user login with valid credentials", %{conn: conn} do
      password = valid_user_password()
      user = user_fixture(%{password: password})

      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#login_form", user: %{email: user.email, password: password, remember_me: true})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "redirects to login page with a flash error if there are no valid credentials", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#login_form",
          user: %{email: "test@email.com", password: "wrongpassword", remember_me: true}
        )

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Invalid email"

      assert redirected_to(conn) == ~p"/login"
    end
  end

  describe "login navigation" do
    test "redirects to registration page when the Register button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/login")

      {:ok, _register_live, register_html} =
        lv
        |> element("main a", "Create an account")
        |> render_click()
        |> follow_redirect(conn, ~p"/register")

      assert register_html =~ "Create account"
    end
  end
end
