defmodule CuratorianWeb.Public.Events.RegisterLiveTest do
  @moduledoc """
  The multi-step registration flow must store custom question answers flat in
  `registration_data`, keyed by the question text — that is the shape the
  Atrium organizer pages and CSV export read. Previously the raw form params
  were merged into the data, so answers landed under the nested
  `"registration" => %{"question_0" => ...}` wrapper and were invisible to
  organizers. Required-question validation is also enforced server-side.
  """

  use CuratorianWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Curatorian.AccountsFixtures

  alias Curatorian.Public
  alias Curatorian.Repo

  describe "registration questions" do
    setup do
      user = user_fixture()

      event =
        event_fixture(%{
          registration_questions: [
            %{"question" => "Apa institusi Anda?", "type" => "text", "required" => true},
            %{
              "question" => "Dari mana Anda tahu event ini?",
              "type" => "text",
              "required" => false
            }
          ]
        })

      %{user: user, event: event}
    end

    test "stores answers flat in registration_data, keyed by question text", %{
      conn: conn,
      user: user,
      event: event
    } do
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/events/#{event.slug}/register")

      # Step 1 → step 2 (questions)
      lv |> element("button", "Lanjutkan") |> render_click()

      lv
      |> form("#registration-questions-form",
        registration: %{
          "question_0" => "Universitas Indonesia",
          "question_1" => "Twitter"
        }
      )
      |> render_submit()

      registration = Public.get_registration_for_user(user.id, event.id)
      assert registration

      data = registration.registration_data

      # Keyed by the question text — the shape the organizer pages read.
      assert data["Apa institusi Anda?"] == "Universitas Indonesia"
      assert data["Dari mana Anda tahu event ini?"] == "Twitter"

      # Account identity auto-filled at the top level.
      assert data["email"] == user.email
      refute Map.has_key?(data, "registration")
      # Free event without manual approval → approved immediately.
      assert registration.status == :approved
    end

    test "server-side validation rejects a missing required answer", %{
      conn: conn,
      user: user,
      event: event
    } do
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/events/#{event.slug}/register")

      lv |> element("button", "Lanjutkan") |> render_click()

      result =
        lv
        |> form("#registration-questions-form", registration: %{"question_0" => ""})
        |> render_submit()

      assert result =~ "Mohon jawab pertanyaan: Apa institusi Anda?"
      refute Public.get_registration_for_user(user.id, event.id)
    end

    test "registers without questions and lands on the confirmation step", %{
      conn: conn,
      user: user
    } do
      event = event_fixture()
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/events/#{event.slug}/register")

      lv |> element("button", "Lanjutkan") |> render_click()

      lv
      |> form("#registration-questions-form")
      |> render_submit()

      registration = Public.get_registration_for_user(user.id, event.id)
      assert registration
      assert registration.registration_data["email"] == user.email
    end
  end

  describe "guest registration" do
    test "anonymous users mount the wizard directly (no forced login)", %{conn: conn} do
      event = event_fixture()

      {:ok, lv, html} = live(conn, ~p"/events/#{event.slug}/register")

      assert html =~ event.title

      # Step 1: the gentle nudge (no forced login).
      assert has_element?(lv, "button", "Lanjutkan")

      # Step 2: the guest identity inputs inside the submitting form.
      lv |> element("button", "Lanjutkan") |> render_click()

      assert has_element?(lv, "#guest-name")
      assert has_element?(lv, "#guest-email")
      assert has_element?(lv, "#guest-phone")
    end

    test "the wizard nudges toward login/Google without blocking guests", %{conn: conn} do
      event = event_fixture()

      {:ok, _lv, html} = live(conn, ~p"/events/#{event.slug}/register")

      # Gentle nudge present…
      assert html =~ "Masuk / daftar dengan Google"
      assert html =~ "login?return_to="
      # …and the guest is still able to register (may skip login).
      assert html =~ "dilewati"
    end

    test "guests see the Turnstile gate on the submitting step, accounts don't", %{conn: conn} do
      event = event_fixture()

      {:ok, lv, _html} = live(conn, ~p"/events/#{event.slug}/register")
      lv |> element("button", "Lanjutkan") |> render_click()

      assert has_element?(lv, "#event_registration_turnstile")

      user = user_fixture()
      conn2 = log_in_user(build_conn(), user)
      {:ok, lv2, _html} = live(conn2, ~p"/events/#{event.slug}/register")
      lv2 |> element("button", "Lanjutkan") |> render_click()

      refute has_element?(lv2, "#event_registration_turnstile")
    end

    test "a guest registers with name and email and gets a participant page", %{conn: conn} do
      event = event_fixture()
      {:ok, lv, _html} = live(conn, ~p"/events/#{event.slug}/register")

      lv |> element("button", "Lanjutkan") |> render_click()

      html =
        lv
        |> form("#registration-questions-form",
          registration: %{
            guest_name: "Siti Rahma",
            guest_email: "siti.rahma@example.com",
            guest_phone: "081234567890"
          }
        )
        |> render_submit()

      assert html =~ "Pendaftaran Berhasil!"
      assert html =~ "Kode pendaftaran di bawah dapat digunakan untuk check-in saat event"
      # The participant page must be reachable immediately — most users never
      # open the confirmation email.
      assert html =~ "Buka Halaman Peserta"

      registration = registration_by_email("siti.rahma@example.com")
      assert has_element?(lv, ~s(a[href="/r/#{registration.token}"]))
      assert registration.guest_name == "Siti Rahma"
      assert is_nil(registration.voile_user_id)
      assert registration.registration_data["email"] == "siti.rahma@example.com"
      assert registration.registration_data["phone"] == "081234567890"
      assert registration.registration_data["name"] == "Siti Rahma"
    end

    test "a guest without an email is rejected with a helpful message", %{conn: conn} do
      event = event_fixture()
      {:ok, lv, _html} = live(conn, ~p"/events/#{event.slug}/register")

      lv |> element("button", "Lanjutkan") |> render_click()

      html =
        lv
        |> form("#registration-questions-form", registration: %{guest_name: "Siti Rahma"})
        |> render_submit()

      assert html =~ "Mohon isi nama dan email untuk mendaftar."
    end

    test "a duplicate guest email for the same event is rejected", %{conn: conn} do
      event = event_fixture()
      {:ok, lv, _html} = live(conn, ~p"/events/#{event.slug}/register")
      lv |> element("button", "Lanjutkan") |> render_click()

      lv
      |> form("#registration-questions-form",
        registration: %{guest_name: "Siti Rahma", guest_email: "siti.rahma@example.com"}
      )
      |> render_submit()

      {:ok, lv2, _html} = live(conn, ~p"/events/#{event.slug}/register")
      lv2 |> element("button", "Lanjutkan") |> render_click()

      # Duplicates redirect to the event page with an error flash (same
      # behavior as duplicate account registrations).
      event_path = "/events/#{event.slug}"

      assert {:error, {:live_redirect, %{to: ^event_path}}} =
               lv2
               |> form("#registration-questions-form",
                 registration: %{guest_name: "Siti Rahma", guest_email: "siti.rahma@example.com"}
               )
               |> render_submit()
    end

    test "the show page CTA offers direct registration with a quiet login link", %{conn: conn} do
      event = event_fixture()

      {:ok, _lv, html} = live(conn, ~p"/events/#{event.slug}")

      assert html =~ "Daftar Sekarang"
      assert html =~ "/events/#{event.slug}/register"
      assert html =~ "Punya akun Curatorian?"
    end
  end

  describe "claim on login" do
    test "a guest registration is claimed when the account email matches", %{conn: conn} do
      event = event_fixture()

      registration =
        registration_fixture(%{
          event_id: event.id,
          guest_name: "Siti Rahma",
          guest_email: "siti.rahma@example.com",
          status: :approved
        })

      user = user_fixture(%{email: "siti.rahma@example.com"})

      {:ok, [claimed]} = Public.claim_guest_registrations(user.id, user.email)

      assert claimed.id == registration.id
      assert claimed.voile_user_id == user.id
      assert is_nil(claimed.guest_name)
      assert is_nil(claimed.guest_email)

      # The record now belongs to the account.
      assert Public.get_registration_for_user(user.id, event.id).id == registration.id
    end

    test "claiming skips events where the user already holds an active seat", %{conn: conn} do
      user = user_fixture(%{email: "budi@example.com"})
      event = event_fixture()

      # The user already holds a seat for the event.
      {:ok, _user_registration} =
        Public.register_for_event(user.id, event.id, requires_approval: false)

      # A guest registration with the same email also exists.
      registration_fixture(%{
        event_id: event.id,
        guest_name: "Budi",
        guest_email: "budi@example.com",
        status: :approved
      })

      {:ok, []} = Public.claim_guest_registrations(user.id, user.email)
    end

    test "claiming is idempotent and skips other guests' rows", %{conn: conn} do
      event = event_fixture()

      mine =
        registration_fixture(%{
          event_id: event.id,
          guest_name: "Siti Rahma",
          guest_email: "siti.rahma@example.com",
          status: :approved
        })

      theirs =
        registration_fixture(%{
          event_id: event.id,
          guest_name: "Orang Lain",
          guest_email: "other@example.com",
          status: :approved
        })

      user = user_fixture(%{email: "siti.rahma@example.com"})

      {:ok, _} = Public.claim_guest_registrations(user.id, user.email)
      {:ok, []} = Public.claim_guest_registrations(user.id, user.email)

      still_guest = Repo.reload!(theirs)
      assert is_nil(still_guest.voile_user_id)
      assert still_guest.guest_email == "other@example.com"
      refute still_guest.id == mine.id
    end

    test "canceled guest registrations are not claimed", %{conn: conn} do
      event = event_fixture()

      registration_fixture(%{
        event_id: event.id,
        guest_name: "Siti Rahma",
        guest_email: "siti.rahma@example.com",
        status: :canceled
      })

      user = user_fixture(%{email: "siti.rahma@example.com"})

      {:ok, []} = Public.claim_guest_registrations(user.id, user.email)
    end
  end

  describe "paid event confirmation" do
    setup do
      %{user: user_fixture()}
    end

    test "explains the payment gate", %{conn: conn, user: user} do
      event = event_fixture(%{is_paid: true, price_idr: 100_000})
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/events/#{event.slug}/register")

      lv |> element("button", "Lanjutkan") |> render_click()

      html =
        lv
        |> form("#registration-questions-form")
        |> render_submit()

      assert html =~ "Selesaikan pembayaran online di bawah"
      assert html =~ "pembayaran akan menyetujui pendaftaran Anda secara otomatis"
      assert html =~ "Bayar Sekarang"
    end

    test "paid event with manual approval explains the review after payment", %{
      conn: conn,
      user: user
    } do
      event = event_fixture(%{is_paid: true, price_idr: 100_000, requires_approval: true})
      conn = log_in_user(conn, user)
      {:ok, lv, _html} = live(conn, ~p"/events/#{event.slug}/register")

      lv |> element("button", "Lanjutkan") |> render_click()

      html =
        lv
        |> form("#registration-questions-form")
        |> render_submit()

      assert html =~ "setelah pembayaran, pendaftaran Anda ditinjau oleh penyelenggara"
    end
  end

  # --- Fixtures ---

  defp event_fixture(attrs \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    base = %Curatorian.Public.Event{
      id: Ecto.UUID.generate(),
      host_user_id: Ecto.UUID.generate(),
      title: "Register Flow #{System.unique_integer([:positive])}",
      slug: "register-flow-#{System.unique_integer([:positive])}",
      event_type: :webinar,
      mode: :online,
      status: :published,
      starts_at: DateTime.add(now, 3_600),
      ends_at: DateTime.add(now, 7_200)
    }

    struct(base, attrs)
    |> Repo.insert!()
  end

  defp registration_fixture(attrs) do
    base = %Curatorian.Public.EventRegistration{
      event_id: Ecto.UUID.generate(),
      registration_code: "REG-" <> (:crypto.strong_rand_bytes(4) |> Base.encode16()),
      token: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower),
      registered_at: DateTime.utc_now() |> DateTime.truncate(:second),
      status: :pending,
      consented_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    struct(base, attrs)
    |> Repo.insert!()
  end

  defp registration_by_email(email) do
    import Ecto.Query

    from(r in Curatorian.Public.EventRegistration,
      where: fragment("lower(?)", r.guest_email) == ^(email |> String.downcase()),
      order_by: [desc: r.registered_at],
      limit: 1
    )
    |> Repo.one!()
  end
end
