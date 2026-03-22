defmodule Curatorian.Public.EventRegistration do
  @moduledoc "Read-only schema for atrium.event_registrations."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "event_registrations" do
    field :event_id, :binary_id
    field :voile_user_id, Ecto.UUID
    field :guest_name, :string
    field :guest_email, :string

    field :status, Ecto.Enum,
      values: [:pending, :approved, :rejected, :waitlisted, :canceled, :no_show],
      default: :pending

    field :registered_at, :utc_datetime
    field :approved_at, :utc_datetime
    field :rejected_at, :utc_datetime
    field :registration_code, :string
    field :amount_paid_idr, :integer

    # Note: event_registrations table in atrium does not have inserted_at/updated_at columns
    # so we disable timestamps for this read-only schema.
    timestamps(inserted_at: false, updated_at: false)
  end
end
