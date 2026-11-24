defmodule CuratorianWeb.UserConfirmationLiveTest do
  use CuratorianWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Curatorian.AccountsFixtures

  alias Curatorian.Accounts
  # Voile auth tables are written through Voile.Repo — assertions must use the
  # same repo (same sandbox connection) to see in-test writes.
  alias Voile.Repo
  alias Voile.Schema.Accounts.UserToken

  setup do
    # The fixture pre-confirms users for login flows; delivering confirmation
    # instructions requires an unconfirmed user.
    user = user_fixture()

    {:ok, user} =
      user
      |> Ecto.Changeset.change(confirmed_at: nil)
      |> Voile.Repo.update()

    %{user: user}
  end

  describe "Confirm user" do
    test "renders confirmation page for a valid token", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, _lv, html} = live(conn, ~p"/users/confirm/#{token}")
      assert html =~ "Konfirmasi akun Anda"
      assert html =~ user.email
    end

    test "renders the error state for an unknown token", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/confirm/invalid-token")
      assert html =~ "Tautan kedaluwarsa"
    end

    test "confirms the given token once", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/users/confirm/#{token}")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/login")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Email confirmed! You can now sign in."

      assert Accounts.get_user!(user.id).confirmed_at
      refute get_session(conn, :user_token)
      assert Repo.all(UserToken) == []
    end

    test "does not confirm with an invalid token", %{conn: conn, user: user} do
      {:ok, _lv, html} = live(conn, ~p"/users/confirm/invalid-token")

      # The error state renders instead of the confirmation form.
      assert html =~ "Tautan kedaluwarsa"
      refute html =~ "#confirmation_form"
      refute Accounts.get_user!(user.id).confirmed_at
      assert Repo.get_by(UserToken, context: "confirm", user_id: user.id) == nil
    end
  end
end
