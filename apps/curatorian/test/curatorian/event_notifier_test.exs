defmodule Curatorian.EventNotifierTest do
  @moduledoc """
  Registration confirmation emails.

  Spec §Security/§Privacy: organizer-controlled content (event title) must be
  HTML-escaped in the HTML part; participant times are shown in the event's
  timezone, not UTC; and the email links to the participant page (`/r/:token`)
  so the personal QR check-in code is reachable.
  """

  use Curatorian.DataCase, async: true

  import Swoosh.TestAssertions

  alias Curatorian.EventNotifier
  alias Curatorian.Repo

  setup do
    user =
      Curatorian.Repo.insert!(%Voile.Schema.Accounts.User{
        username: "notifier-#{System.unique_integer([:positive])}",
        email: "budi-#{System.unique_integer([:positive])}@example.com",
        hashed_password: "test-hash",
        registration_date: Date.utc_today(),
        node_id: 1
      })

    %{user: user}
  end

  describe "deliver_registration_confirmation/2" do
    test "sends to the registrant's email with the participant page link", %{user: user} do
      event = event_fixture()
      registration = registration_fixture(user, event)

      assert {:ok, :sent} =
               EventNotifier.deliver_registration_confirmation(registration, event)

      assert_received {:email, email}

      assert email.to == [{"", user.email}]
      assert email.text_body =~ "/r/#{registration.token}"
      assert email.html_body =~ "/r/#{registration.token}"
      assert email.html_body =~ "Halaman peserta Anda"
      assert email.subject =~ event.title
    end

    test "escapes organizer-controlled HTML in the HTML body", %{user: user} do
      event = event_fixture(%{title: "<script>alert('x')</script> Webinar"})
      registration = registration_fixture(user, event)

      assert {:ok, :sent} =
               EventNotifier.deliver_registration_confirmation(registration, event)

      assert_received {:email, email}

      # The HTML part must not contain raw markup from the title...
      refute email.html_body =~ "<script>alert"
      # ...but the text part keeps the literal title (it is plain text).
      assert email.text_body =~ event.title
      # The escaped form is present.
      assert email.html_body =~ "&lt;script&gt;"
    end

    test "renders times in the event's timezone, not UTC", %{user: user} do
      # 2026-03-10 03:00 UTC == 10:00 WIB.
      starts_at = ~U[2026-03-10 03:00:00Z]

      event = event_fixture(%{starts_at: starts_at, ends_at: DateTime.add(starts_at, 7_200)})
      registration = registration_fixture(user, event)

      assert {:ok, :sent} =
               EventNotifier.deliver_registration_confirmation(registration, event)

      assert_received {:email, email}

      assert email.text_body =~ "10:00"
      refute email.text_body =~ "UTC"
    end

    test "mentions completing payment for paid events", %{user: user} do
      event = event_fixture(%{is_paid: true, price_idr: 100_000})
      registration = registration_fixture(user, event)

      assert {:ok, :sent} =
               EventNotifier.deliver_registration_confirmation(registration, event)

      assert_received {:email, email}
      assert email.text_body =~ "Selesaikan pembayaran untuk mengamankan slot"
    end

    test "omits the participant link for registrations without a token", %{user: user} do
      event = event_fixture()
      registration = registration_fixture(user, event, %{token: nil})

      assert {:ok, :sent} =
               EventNotifier.deliver_registration_confirmation(registration, event)

      assert_received {:email, email}
      refute email.html_body =~ "/r/"
    end

    test "sends to the guest email for guest registrations (no account)", %{user: user} do
      event = event_fixture()

      registration =
        registration_fixture(user, event, %{
          voile_user_id: nil,
          guest_name: "Siti Rahma",
          guest_email: "siti.rahma@example.com"
        })

      assert {:ok, :sent} =
               EventNotifier.deliver_registration_confirmation(registration, event)

      assert_received {:email, email}
      assert email.to == [{"", "siti.rahma@example.com"}]
      assert email.text_body =~ "/r/#{registration.token}"
    end
  end

  # --- Fixtures ---

  defp event_fixture(attrs \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    base = %Curatorian.Public.Event{
      id: Ecto.UUID.generate(),
      host_user_id: Ecto.UUID.generate(),
      title: "Notifier Event #{System.unique_integer([:positive])}",
      slug: "notifier-event-#{System.unique_integer([:positive])}",
      event_type: :webinar,
      mode: :online,
      status: :published,
      starts_at: DateTime.add(now, 3_600),
      ends_at: DateTime.add(now, 7_200)
    }

    struct(base, attrs)
    |> Repo.insert!()
  end

  defp registration_fixture(user, event, overrides \\ %{}) do
    base = %Curatorian.Public.EventRegistration{
      event_id: event.id,
      voile_user_id: user.id,
      registration_code: "REG-" <> (:crypto.strong_rand_bytes(4) |> Base.encode16()),
      token: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower),
      registered_at: DateTime.utc_now() |> DateTime.truncate(:second),
      status: :pending,
      consented_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    struct(base, overrides)
    |> Repo.insert!()
  end
end
