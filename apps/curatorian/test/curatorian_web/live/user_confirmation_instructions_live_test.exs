defmodule CuratorianWeb.UserConfirmationInstructionsLiveTest do
  use CuratorianWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Curatorian.AccountsFixtures

  # Voile auth tables are written through Voile.Repo — assertions must use the
  # same repo (same sandbox connection) to see in-test writes.
  alias Voile.Repo
  alias Voile.Schema.Accounts.UserToken

  describe "Resend confirmation" do
    test "renders the pending confirmation page with the registrant's email", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/pending_confirmation?email=user@example.com")

      assert html =~ "Cek kotak masuk Anda"
      assert html =~ "user@example.com"
    end

    test "sends a new confirmation token for an unconfirmed user", %{conn: conn} do
      user = user_fixture()

      {:ok, user} =
        user
        |> Ecto.Changeset.change(confirmed_at: nil)
        |> Voile.Repo.update()

      {:ok, lv, _html} = live(conn, ~p"/users/pending_confirmation?email=#{user.email}")

      html = lv |> element("#resend_form") |> render_submit()

      assert html =~ "If that email belongs to an unconfirmed account"
      assert token = Repo.get_by!(UserToken, user_id: user.id)
      assert token.context == "confirm"
    end

    test "does not send a token if the user is already confirmed", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/pending_confirmation?email=#{user.email}")

      html = lv |> element("#resend_form") |> render_submit()

      # One neutral message for every outcome — never reveals the state.
      assert html =~ "If that email belongs to an unconfirmed account"
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not send a token for an unknown email", %{conn: conn} do
      {:ok, lv, _html} =
        live(conn, ~p"/users/pending_confirmation?email=unknown@example.com")

      html = lv |> element("#resend_form") |> render_submit()

      assert html =~ "If that email belongs to an unconfirmed account"
      assert Repo.all(UserToken) == []
    end
  end
end
