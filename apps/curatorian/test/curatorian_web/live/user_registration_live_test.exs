defmodule CuratorianWeb.UserRegistrationLiveTest do
  use CuratorianWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Curatorian.AccountsFixtures

  alias Curatorian.Accounts
  # Voile auth tables are written through Voile.Repo — assertions must use the
  # same repo (same sandbox connection) to see in-test writes.
  alias Voile.Repo
  alias Voile.Schema.Accounts.UserToken

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/register")

      assert html =~ "Buat akun Anda"
      assert html =~ "Masuk"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())

      {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/register")
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "with spaces", "password" => "short"})

      assert result =~ "Buat akun Anda"
      assert result =~ "must have the @ sign"
    end
  end

  describe "register user" do
    test "creates an account and leads to the pending confirmation page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/register")

      email = unique_user_email()

      {:ok, _conn2, html} =
        lv
        |> form("#registration_form", user: %{email: email, password: valid_user_password()})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/pending_confirmation?email=#{email}")

      assert html =~ "Cek kotak masuk Anda"
      assert html =~ email

      user = Accounts.get_user_by_email(email)
      assert user
      refute user.confirmed_at
      # A confirmation email was delivered with a fresh confirm token.
      assert Repo.get_by!(UserToken, user_id: user.id).context == "confirm"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      %{email: email} = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/register")

      result =
        lv
        |> form("#registration_form", user: %{email: email, password: valid_user_password()})
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Masuk link is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/register")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Masuk")
        |> render_click()
        |> follow_redirect(conn, ~p"/login")

      assert login_html =~ "Masuk ke akun Curatorian Anda"
    end
  end
end
