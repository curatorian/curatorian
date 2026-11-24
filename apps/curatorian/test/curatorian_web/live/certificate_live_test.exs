defmodule CuratorianWeb.Public.Events.CertificateLiveTest do
  @moduledoc """
  The certificate page must not leak the recipient's email address.

  Spec §4.5: the verification page (`/certificates/verify/:token`) shows the
  certificate number, participant name, event, and status — "No email
  addresses or other personal data on this page". The email is only shown on
  the owner's own view (`/certificates/:id` when logged in as the recipient).
  """

  use CuratorianWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Curatorian.AccountsFixtures

  alias Curatorian.Public
  alias Curatorian.Repo

  describe "verification page (/certificates/verify/:token)" do
    test "shows the recipient name but never the email", %{conn: conn} do
      %{certificate: certificate} = certificate_fixture()

      {:ok, _lv, html} = live(conn, ~p"/certificates/verify/#{certificate.verification_token}")

      assert html =~ certificate.recipient_name
      assert html =~ "Sertifikat Terverifikasi"
      refute html =~ certificate.recipient_email
      refute html =~ "Email"
    end

    test "redirects for a revoked or unknown token", %{conn: conn} do
      %{certificate: certificate} = certificate_fixture(%{is_valid: false})

      {:error, {:live_redirect, %{to: "/events"}}} =
        live(conn, ~p"/certificates/verify/#{certificate.verification_token}")
    end
  end

  describe "certificate page (/certificates/:id)" do
    test "the logged-in owner sees their own email", %{conn: conn} do
      user = user_fixture()
      %{certificate: certificate} = certificate_fixture(%{voile_user_id: user.id})

      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/certificates/#{certificate.id}")

      assert html =~ certificate.recipient_name
      assert html =~ certificate.recipient_email
    end

    test "a guest certificate (no owner account) never exposes the email", %{conn: conn} do
      %{certificate: certificate} = certificate_fixture(%{voile_user_id: nil})

      {:ok, _lv, html} = live(conn, ~p"/certificates/#{certificate.id}")

      assert html =~ certificate.recipient_name
      refute html =~ certificate.recipient_email
      refute html =~ "Email"
    end

    test "a different user is denied access to someone else's certificate", %{conn: conn} do
      owner = user_fixture()
      %{certificate: certificate} = certificate_fixture(%{voile_user_id: owner.id})

      conn = log_in_user(conn, user_fixture())

      assert {:error,
              {:live_redirect,
               %{
                 to: "/foyer",
                 flash: %{"error" => "Anda tidak memiliki akses ke sertifikat ini."}
               }}} =
               live(conn, ~p"/certificates/#{certificate.id}")
    end
  end

  describe "organization-designed certificate" do
    test "renders the template background, layout and signature", %{conn: conn} do
      %{certificate: certificate} = certificate_fixture()
      template = template_fixture()
      certificate = put_template(certificate, template)

      {:ok, lv, _html} = live(conn, ~p"/certificates/#{certificate.id}")

      bg_url = Public.asset_url("/uploads/certificates/bg.png")
      sig_url = Public.asset_url("/uploads/certificates/sig.png")

      assert has_element?(lv, "#templated-certificate")
      assert has_element?(lv, ~s(#templated-certificate img[src="#{bg_url}"]))
      assert has_element?(lv, "#templated-certificate", certificate.recipient_name)
      assert has_element?(lv, "#templated-certificate", certificate.event_title)
      assert has_element?(lv, "#templated-certificate", certificate.certificate_number)
      assert has_element?(lv, "#templated-certificate", "Chrisna Adhi Pranoto")
      assert has_element?(lv, "#templated-certificate", "Curatorian Developer")
      assert has_element?(lv, ~s(#templated-certificate img[src="#{sig_url}"]))
      # The built-in design is not rendered when a template exists.
      refute has_element?(lv, "#certificate-print-area", "Sertifikat Penghargaan")
    end

    test "respects the template's hidden fields", %{conn: conn} do
      %{certificate: certificate} = certificate_fixture()
      template = template_fixture(%{show_cert_number: false})
      certificate = put_template(certificate, template)

      {:ok, lv, _html} = live(conn, ~p"/certificates/#{certificate.id}")

      refute has_element?(lv, "#templated-certificate", certificate.certificate_number)
      assert has_element?(lv, "#templated-certificate", certificate.recipient_name)
    end

    test "falls back to the event's template when the certificate has no snapshot", %{conn: conn} do
      %{certificate: certificate, event: event} = certificate_fixture()
      template = template_fixture(%{signature_name: "Event Template Signer"})

      event
      |> Ecto.Changeset.change(certificate_template_id: template.id)
      |> Repo.update!()

      {:ok, lv, _html} = live(conn, ~p"/certificates/#{certificate.id}")

      assert has_element?(lv, "#templated-certificate", "Event Template Signer")
    end

    test "falls back to the built-in design for a soft-deleted template", %{conn: conn} do
      %{certificate: certificate} = certificate_fixture()
      template = template_fixture(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
      certificate = put_template(certificate, template)

      {:ok, lv, _html} = live(conn, ~p"/certificates/#{certificate.id}")

      refute has_element?(lv, "#templated-certificate")
      assert has_element?(lv, "#certificate-print-area", "Sertifikat Penghargaan")
    end

    test "keeps the built-in design when neither certificate nor event has a template", %{
      conn: conn
    } do
      %{certificate: certificate} = certificate_fixture()

      {:ok, lv, _html} = live(conn, ~p"/certificates/#{certificate.id}")

      refute has_element?(lv, "#templated-certificate")
      assert has_element?(lv, "#certificate-print-area", "Sertifikat Penghargaan")
    end
  end

  # --- Fixtures ---

  defp template_fixture(overrides \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %Curatorian.Public.EventCertificateTemplate{
      id: Ecto.UUID.generate(),
      name: "Org Certificate #{System.unique_integer([:positive])}",
      voile_user_id: Ecto.UUID.generate(),
      background_image_url: "/uploads/certificates/bg.png",
      background_color: "#FFFFFF",
      font_family: "Georgia",
      layout_config: %{
        "participant_name" => %{"x" => 50, "y" => 50, "size" => 30, "align" => "center"}
      },
      signature_name: "Chrisna Adhi Pranoto",
      signature_title: "Curatorian Developer",
      signature_image_url: "/uploads/certificates/sig.png",
      inserted_at: now,
      updated_at: now
    }
    |> Map.merge(overrides)
    |> Repo.insert!()
  end

  defp put_template(certificate, template) do
    certificate
    |> Ecto.Changeset.change(template_id: template.id)
    |> Repo.update!()
  end

  defp event_fixture do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %Curatorian.Public.Event{
      id: Ecto.UUID.generate(),
      host_user_id: Ecto.UUID.generate(),
      title: "Cert Event #{System.unique_integer([:positive])}",
      slug: "cert-event-#{System.unique_integer([:positive])}",
      event_type: :webinar,
      mode: :online,
      status: :published,
      starts_at: DateTime.add(now, 3_600),
      ends_at: DateTime.add(now, 7_200)
    }
    |> Repo.insert!()
  end

  defp certificate_fixture(overrides \\ %{}) do
    event = event_fixture()
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    certificate =
      %Curatorian.Public.EventCertificate{
        id: Ecto.UUID.generate(),
        event_id: event.id,
        registration_id: Ecto.UUID.generate(),
        recipient_name: "Budi Santoso",
        recipient_email: "budi-#{System.unique_integer([:positive])}@example.com",
        certificate_number:
          "CERT/2026/TEST/#{System.unique_integer([:positive]) |> Integer.to_string() |> String.pad_leading(4, "0")}",
        verification_token: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower),
        event_title: event.title,
        event_date: Date.utc_today(),
        issued_at: now
      }
      |> Map.merge(overrides)
      |> Repo.insert!()

    %{event: event, certificate: certificate}
  end
end
