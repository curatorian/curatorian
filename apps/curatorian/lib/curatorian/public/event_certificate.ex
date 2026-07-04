defmodule Curatorian.Public.EventCertificate do
  @moduledoc "Read-only schema for atrium.event_certificates."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @timestamps_opts false
  @schema_prefix "atrium"

  schema "event_certificates" do
    field :event_id, :binary_id
    field :registration_id, :binary_id
    field :attendance_id, :binary_id

    # Recipient snapshot
    field :recipient_name, :string
    field :recipient_email, :string
    field :voile_user_id, Ecto.UUID

    field :certificate_number, :string
    field :template_id, :binary_id

    # Verification
    field :verification_token, :string

    # Content snapshot
    field :event_title, :string
    field :event_date, :date
    field :event_duration_minutes, :integer
    field :host_name, :string

    # PDF
    field :pdf_url, :string
    field :pdf_generated_at, :utc_datetime

    # Usage
    field :download_count, :integer, default: 0
    field :last_downloaded_at, :utc_datetime

    # Validity
    field :is_valid, :boolean, default: true
    field :revoked_at, :utc_datetime
    field :revocation_reason, :string

    field :issued_at, :utc_datetime
  end
end
