defmodule CuratorianWeb.Foyer.FoyerLiveTest do
  @moduledoc """
  The Foyer dashboard tabs.

  Regression: switching to the "Pembayaran" (payments) tab crashed with
  `DateTime.to_date(~N[...])` — atrium's event_payments rows load
  `inserted_at` as NaiveDateTime, but the formatter only handled DateTime.
  """

  use CuratorianWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Curatorian.AccountsFixtures

  alias Curatorian.Public
  alias Curatorian.Repo

  describe "payments tab" do
    test "renders payment rows with naive timestamps", %{conn: conn} do
      user = user_fixture()
      event = event_fixture()

      {:ok, registration} =
        Public.register_for_event(user.id, event.id, requires_approval: false)

      insert_payment(%{
        event_id: event.id,
        registration_id: registration.id,
        voile_user_id: user.id,
        status: :pending,
        gross_amount_idr: 25_000,
        net_amount_idr: 25_000,
        gateway_order_id: "EVT-TEST1234"
      })

      {:ok, lv, _html} = live(conn |> log_in_user(user), ~p"/foyer")

      html =
        lv
        |> element("#tab-payments")
        |> render_click()

      assert html =~ "EVT-TEST1234"
      assert html =~ "25.000"
    end
  end

  # --- Fixtures ---

  defp event_fixture do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %Public.Event{
      id: Ecto.UUID.generate(),
      host_user_id: Ecto.UUID.generate(),
      title: "Foyer Pay #{System.unique_integer([:positive])}",
      slug: "foyer-pay-#{System.unique_integer([:positive])}",
      event_type: :webinar,
      mode: :online,
      status: :published,
      starts_at: DateTime.add(now, 3_600),
      ends_at: DateTime.add(now, 7_200)
    }
    |> Repo.insert!()
  end

  defp insert_payment(attrs) do
    %Public.EventPayment{id: Ecto.UUID.generate()}
    |> Ecto.Changeset.change(attrs)
    |> Repo.insert!()
  end
end
