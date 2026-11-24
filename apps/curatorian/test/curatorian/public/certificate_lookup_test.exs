defmodule Curatorian.Public.CertificateLookupTest do
  @moduledoc """
  Public certificate verification lookups.

  Spec §Security: rate limit verification lookups. `get_certificate_by_token/1`
  is the public verification page's lookup — hammering it returns nil (the
  page's neutral "not found" response) once the limit is hit.
  """

  use Curatorian.DataCase, async: true

  alias Curatorian.Public

  describe "get_certificate_by_token/1" do
    test "returns the valid certificate for its token" do
      %{certificate: certificate} = certificate_fixture()

      assert found = Public.get_certificate_by_token(certificate.verification_token)
      assert found.id == certificate.id
    end

    test "rate limits lookups per token" do
      %{certificate: certificate} = certificate_fixture()

      # First 30 lookups within the window succeed (limit is 30/minute).
      results =
        for _ <- 1..30, do: Public.get_certificate_by_token(certificate.verification_token)

      assert Enum.all?(results, &(&1 != nil))

      # The 31st is blocked — same neutral response as an unknown token.
      assert Public.get_certificate_by_token(certificate.verification_token) == nil
    end
  end

  describe "get_certificate_template/1" do
    test "returns a live template" do
      template = template_fixture()

      assert found = Public.get_certificate_template(template.id)
      assert found.id == template.id
    end

    test "ignores nil, unknown and soft-deleted templates" do
      deleted =
        template_fixture(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})

      assert Public.get_certificate_template(nil) == nil
      assert Public.get_certificate_template(Ecto.UUID.generate()) == nil
      assert Public.get_certificate_template(deleted.id) == nil
    end
  end

  # --- Fixtures ---

  defp template_fixture(overrides \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %Curatorian.Public.EventCertificateTemplate{
      id: Ecto.UUID.generate(),
      name: "Lookup Template #{System.unique_integer([:positive])}",
      inserted_at: now,
      updated_at: now
    }
    |> Map.merge(overrides)
    |> Repo.insert!()
  end

  defp certificate_fixture do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    event =
      %Curatorian.Public.Event{
        id: Ecto.UUID.generate(),
        host_user_id: Ecto.UUID.generate(),
        title: "Cert Lookup #{System.unique_integer([:positive])}",
        slug: "cert-lookup-#{System.unique_integer([:positive])}",
        event_type: :webinar,
        mode: :online,
        status: :published,
        starts_at: DateTime.add(now, 3_600),
        ends_at: DateTime.add(now, 7_200)
      }
      |> Repo.insert!()

    certificate =
      %Curatorian.Public.EventCertificate{
        id: Ecto.UUID.generate(),
        event_id: event.id,
        registration_id: Ecto.UUID.generate(),
        recipient_name: "Budi Santoso",
        recipient_email: "budi@example.com",
        certificate_number: "CERT/2026/LOOK/#{System.unique_integer([:positive])}",
        verification_token: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower),
        event_title: event.title,
        event_date: Date.utc_today(),
        issued_at: now
      }
      |> Repo.insert!()

    %{event: event, certificate: certificate}
  end
end
