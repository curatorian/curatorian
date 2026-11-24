defmodule CuratorianWeb.Public.Events.ShowLiveTest do
  @moduledoc """
  Registration status messaging on the public event page.

  On paid events, `:pending` means *awaiting payment* (payment is the
  approval gate) — the copy must say so, not "menunggu konfirmasi
  penyelenggara".
  """

  use CuratorianWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Curatorian.AccountsFixtures

  alias Curatorian.Public
  alias Curatorian.Repo

  describe "paid event status messaging" do
    test "an unpaid pending registration shows Menunggu Pembayaran", %{conn: conn} do
      user = user_fixture()
      event = event_fixture(%{is_paid: true, price_idr: 100_000})

      {:ok, _registration} = Public.register_for_event(user.id, event.id)
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/events/#{event.slug}")

      assert html =~ "Menunggu Pembayaran"
      assert html =~ "Selesaikan pembayaran untuk mengamankan slot Anda"
      assert html =~ "Bayar Sekarang"
      refute html =~ "Menunggu Konfirmasi"
    end

    test "a free manual-approval event keeps the Menunggu Konfirmasi copy", %{conn: conn} do
      user = user_fixture()
      event = event_fixture(%{requires_approval: true})

      {:ok, _registration} = Public.register_for_event(user.id, event.id)
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/events/#{event.slug}")

      assert html =~ "Menunggu Konfirmasi"
      assert html =~ "ditinjau oleh penyelenggara"
      refute html =~ "Menunggu Pembayaran"
    end
  end

  describe "registration availability copy (#17)" do
    test "a full event says Kuota Penuh, not Pendaftaran Belum Dibuka", %{conn: conn} do
      user = user_fixture()
      event = event_fixture(%{max_attendees: 1, registration_count: 1})

      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, ~p"/events/#{event.slug}")

      assert html =~ "Kuota Penuh"
      refute html =~ "Pendaftaran Belum Dibuka"
    end

    test "a closed registration window says Pendaftaran Ditutup", %{conn: conn} do
      user = user_fixture()
      past = DateTime.add(DateTime.utc_now(), -3_600) |> DateTime.truncate(:second)
      event = event_fixture(%{registration_closes_at: past})

      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, ~p"/events/#{event.slug}")

      assert html =~ "Pendaftaran Ditutup"
      refute html =~ "Pendaftaran Belum Dibuka"
    end

    test "a not-yet-open event keeps the Pendaftaran Belum Dibuka copy", %{conn: conn} do
      user = user_fixture()
      future = DateTime.add(DateTime.utc_now(), 3_600) |> DateTime.truncate(:second)
      event = event_fixture(%{registration_opens_at: future})

      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, ~p"/events/#{event.slug}")

      assert html =~ "Pendaftaran Belum Dibuka"
    end

    test "a canceled event is marked EventCancelled in JSON-LD" do
      alias CuratorianWeb.Public.Events.ShowLive

      # Canceled events 404 on the public page (get_event_by_slug filters
      # them out), so the status URL is asserted directly.
      assert ShowLive.event_status_url(:canceled) == "https://schema.org/EventCancelled"
      assert ShowLive.event_status_url(:published) == "https://schema.org/EventScheduled"
      assert ShowLive.event_status_url(:ongoing) == "https://schema.org/EventScheduled"
    end

    test "a scheduled event keeps EventScheduled in JSON-LD", %{conn: conn} do
      user = user_fixture()
      event = event_fixture()

      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, ~p"/events/#{event.slug}")

      assert html =~ "EventScheduled"
    end
  end

  describe "cover image" do
    test "renders the cover through the Atrium asset host, uncropped", %{conn: conn} do
      event = event_fixture(%{cover_image_url: "/uploads/covers/poster.png"})

      {:ok, lv, _html} = live(conn, ~p"/events/#{event.slug}")

      url = Public.asset_url("/uploads/covers/poster.png")

      assert has_element?(lv, "#event-cover")
      assert has_element?(lv, ~s(#event-cover img[src="#{url}"]))
      assert has_element?(lv, ~s(#event-cover img.object-contain))
      refute has_element?(lv, ~s(#event-cover img.object-cover))
    end

    test "omits the cover block when the event has no cover", %{conn: conn} do
      event = event_fixture()

      {:ok, lv, _html} = live(conn, ~p"/events/#{event.slug}")

      refute has_element?(lv, "#event-cover")
    end
  end

  # --- Fixtures ---

  defp event_fixture(attrs \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    base = %Curatorian.Public.Event{
      id: Ecto.UUID.generate(),
      host_user_id: Ecto.UUID.generate(),
      title: "Show Msg #{System.unique_integer([:positive])}",
      slug: "show-msg-#{System.unique_integer([:positive])}",
      event_type: :webinar,
      mode: :online,
      status: :published,
      starts_at: DateTime.add(now, 3_600),
      ends_at: DateTime.add(now, 7_200)
    }

    struct(base, attrs)
    |> Repo.insert!()
  end
end
