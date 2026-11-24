defmodule CuratorianWeb.Public.ParticipantPageTest do
  @moduledoc """
  The participant page (`/r/:token`).

  The join link must be discoverable here: previously it was only delivered
  in the 1-hour reminder email, so participants who ignored (or never
  received) the email couldn't find the meeting link.
  """

  use CuratorianWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Curatorian.Repo

  describe "join link" do
    test "approved participants of online events see the join link", %{conn: conn} do
      registration = registration_fixture(%{}, %{meeting_url: "https://zoom.us/j/123"})

      {:ok, _lv, html} = live(conn, ~p"/r/#{registration.token}")

      assert html =~ "Bergabung ke Sesi"
      assert html =~ "https://zoom.us/j/123"
    end

    test "pending participants do not see the join link", %{conn: conn} do
      registration =
        registration_fixture(%{status: :pending}, %{meeting_url: "https://zoom.us/j/123"})

      {:ok, _lv, html} = live(conn, ~p"/r/#{registration.token}")

      refute html =~ "Bergabung ke Sesi"
      refute html =~ "https://zoom.us/j/123"
    end

    test "offline events do not show a join block", %{conn: conn} do
      registration = registration_fixture(%{}, %{mode: :offline})

      {:ok, _lv, html} = live(conn, ~p"/r/#{registration.token}")

      refute html =~ "Bergabung ke Sesi"
    end

    test "approved participants without a meeting_url do not see a join block", %{conn: conn} do
      registration = registration_fixture(%{}, %{})

      {:ok, _lv, html} = live(conn, ~p"/r/#{registration.token}")

      refute html =~ "Bergabung ke Sesi"
    end
  end

  describe "payment button" do
    test "unpaid paid events show a Bayar Sekarang button (guests pay here)", %{conn: conn} do
      registration =
        registration_fixture(%{status: :pending}, %{is_paid: true, price_idr: 100_000})

      {:ok, _lv, html} = live(conn, ~p"/r/#{registration.token}")

      assert html =~ "Menunggu Pembayaran"
      assert html =~ "Bayar Sekarang"
    end

    test "paid-and-approved registrations do not show the payment button", %{conn: conn} do
      registration =
        registration_fixture(%{status: :approved}, %{is_paid: true, price_idr: 100_000})

      {:ok, _lv, html} = live(conn, ~p"/r/#{registration.token}")

      refute html =~ "Bayar Sekarang"
    end
  end

  # --- Fixtures ---

  defp event_fixture(overrides \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    base = %Curatorian.Public.Event{
      id: Ecto.UUID.generate(),
      host_user_id: Ecto.UUID.generate(),
      title: "Participant Pg #{System.unique_integer([:positive])}",
      slug: "participant-pg-#{System.unique_integer([:positive])}",
      event_type: :webinar,
      mode: :online,
      status: :published,
      starts_at: DateTime.add(now, 3_600),
      ends_at: DateTime.add(now, 7_200)
    }

    struct(base, overrides)
    |> Repo.insert!()
  end

  # First map overrides the registration, second the event (defaults: approved
  # registration on a published online event with no meeting_url).
  defp registration_fixture(registration_overrides, event_overrides) do
    event = event_fixture(event_overrides)

    base = %Curatorian.Public.EventRegistration{
      event_id: event.id,
      voile_user_id: Ecto.UUID.generate(),
      registration_code: "REG-" <> (:crypto.strong_rand_bytes(4) |> Base.encode16()),
      token: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower),
      registered_at: DateTime.utc_now() |> DateTime.truncate(:second),
      status: :approved,
      consented_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    struct(base, registration_overrides)
    |> Repo.insert!()
  end
end
