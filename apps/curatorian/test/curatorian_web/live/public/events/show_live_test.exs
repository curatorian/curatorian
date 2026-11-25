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

      {:ok, _registration} =
        Public.register_for_event(user.id, event.id, requires_approval: event.requires_approval)

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

      {:ok, _registration} =
        Public.register_for_event(user.id, event.id, requires_approval: event.requires_approval)

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

  describe "cover lightbox" do
    test "clicking the cover opens the image modal and it can be closed", %{conn: conn} do
      event = event_fixture(%{cover_image_url: "/uploads/covers/lightbox.png"})

      {:ok, lv, _html} = live(conn, ~p"/events/#{event.slug}")

      refute has_element?(lv, "#cover-modal")

      lv |> element("#cover-image-button") |> render_click()

      assert has_element?(lv, "#cover-modal")

      assert has_element?(
               lv,
               ~s(#cover-modal img[src="http://localhost:4001/uploads/covers/lightbox.png"])
             )

      lv |> element(~s(#cover-modal button[aria-label="Tutup gambar"])) |> render_click()

      refute has_element?(lv, "#cover-modal")
    end
  end

  describe "public visibility" do
    test "a published event whose start time has passed stays reachable", %{conn: conn} do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      event =
        event_fixture(%{
          starts_at: DateTime.add(now, -7_200),
          ends_at: DateTime.add(now, -3_600)
        })

      {:ok, _lv, html} = live(conn, ~p"/events/#{event.slug}")

      assert html =~ event.title
    end

    test "a completed event is reachable and says it has ended", %{conn: conn} do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      event =
        event_fixture(%{
          status: :completed,
          starts_at: DateTime.add(now, -86_400),
          ends_at: DateTime.add(now, -82_800)
        })

      {:ok, _lv, html} = live(conn, ~p"/events/#{event.slug}")

      assert html =~ event.title
      assert html =~ "Event Telah Selesai"
    end

    test "a canceled event still 404s", %{conn: conn} do
      event = event_fixture(%{status: :canceled})

      assert_raise Ecto.NoResultsError, fn -> live(conn, ~p"/events/#{event.slug}") end
    end

    test "a draft event still 404s", %{conn: conn} do
      event = event_fixture(%{status: :draft})

      assert_raise Ecto.NoResultsError, fn -> live(conn, ~p"/events/#{event.slug}") end
    end
  end

  describe "organizer attribution" do
    test "shows the host user's display name instead of a generic label", %{conn: conn} do
      host_id = Ecto.UUID.generate()

      Repo.insert!(%Curatorian.Public.UserProfile{
        id: Ecto.UUID.generate(),
        voile_user_id: host_id,
        voile_node_id: 1,
        username: "budi-org-owner",
        display_name: "Budi Santoso"
      })

      event = event_fixture(%{host_user_id: host_id})

      {:ok, _lv, html} = live(conn, ~p"/events/#{event.slug}")

      assert html =~ "Budi Santoso"
      refute html =~ "Diselenggarakan oleh pengguna"
    end
  end

  describe "OpenGraph image" do
    test "uses the event cover hosted on Atrium", %{conn: conn} do
      event = event_fixture(%{cover_image_url: "/uploads/covers/og-poster.png"})

      {:ok, _lv, html} = live(conn, ~p"/events/#{event.slug}")

      assert html =~ "http://localhost:4001/uploads/covers/og-poster.png"
    end

    test "falls back to the Curatorian default when there is no cover", %{conn: conn} do
      event = event_fixture()

      {:ok, _lv, html} = live(conn, ~p"/events/#{event.slug}")

      assert html =~ "http://localhost:4000/images/og_image.webp"
    end
  end

  describe "participant access panel" do
    test "approved participants get join, QR, session code, materials and their participant page",
         %{conn: conn} do
      user = user_fixture()

      event =
        event_fixture(%{
          mode: :online,
          status: :ongoing,
          attendance_mode: "session_code",
          starts_at: DateTime.add(DateTime.utc_now(), -3_600) |> DateTime.truncate(:second),
          ends_at: DateTime.add(DateTime.utc_now(), 3_600) |> DateTime.truncate(:second),
          meeting_url: "https://zoom.us/j/participant-access",
          material_url: "https://drive.google.com/drive/folders/abc"
        })

      {:ok, registration} =
        Public.register_for_event(user.id, event.id, requires_approval: event.requires_approval)

      assert registration.status == :approved
      assert Public.get_registration_for_user(user.id, event.id)

      {:ok, lv, html} = live(log_in_user(conn, user), ~p"/events/#{event.slug}")

      assert html =~ "Akses Peserta"
      assert has_element?(lv, ~s(a[href="https://zoom.us/j/participant-access"]))
      assert has_element?(lv, "img#participant-qr")
      assert html =~ "Kode Sesi"
      assert has_element?(lv, ~s(a[href="https://drive.google.com/drive/folders/abc"]))
      assert has_element?(lv, ~s(a[href="/r/#{registration.token}"]))
      refute html =~ "Daftar Sekarang"
    end

    test "offline participants see the venue instead of a join link", %{conn: conn} do
      user = user_fixture()

      event =
        event_fixture(%{
          mode: :offline,
          status: :ongoing,
          venue_name: "Gedung Arsip Nasional",
          venue_city: "Bandung"
        })

      {:ok, _registration} =
        Public.register_for_event(user.id, event.id, requires_approval: event.requires_approval)

      {:ok, lv, html} = live(log_in_user(conn, user), ~p"/events/#{event.slug}")

      assert html =~ "Gedung Arsip Nasional"
      refute has_element?(lv, ~s(#participant-access a[href^="https://zoom"]))
    end

    test "pending registrations get no access panel and no materials", %{conn: conn} do
      user = user_fixture()

      event =
        event_fixture(%{
          requires_approval: true,
          material_url: "https://drive.google.com/drive/folders/hidden"
        })

      {:ok, registration} =
        Public.register_for_event(user.id, event.id, requires_approval: event.requires_approval)

      assert registration.status == :pending

      {:ok, lv, html} = live(log_in_user(conn, user), ~p"/events/#{event.slug}")

      refute html =~ "Akses Peserta"
      refute has_element?(lv, ~s(a[href="https://drive.google.com/drive/folders/hidden"]))
    end

    test "shows the certificate button once a certificate is issued", %{conn: conn} do
      user = user_fixture()
      event = event_fixture(%{})

      {:ok, registration} =
        Public.register_for_event(user.id, event.id, requires_approval: event.requires_approval)

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      certificate =
        %Curatorian.Public.EventCertificate{
          id: Ecto.UUID.generate(),
          event_id: event.id,
          registration_id: registration.id,
          recipient_name: "Budi Santoso",
          certificate_number: "CERT/TEST/#{System.unique_integer([:positive])}",
          verification_token: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower),
          event_title: event.title,
          event_date: Date.utc_today(),
          issued_at: now
        }
        |> Repo.insert!()

      {:ok, lv, _html} = live(log_in_user(conn, user), ~p"/events/#{event.slug}")

      assert has_element?(lv, ~s(a[href="/certificates/#{certificate.id}"]))
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
