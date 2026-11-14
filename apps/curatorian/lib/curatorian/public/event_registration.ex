defmodule Curatorian.Public.EventRegistration do
  @moduledoc "Schema for atrium.event_registrations (read + write from Curatorian)."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @schema_prefix "atrium"

  schema "event_registrations" do
    field :event_id, :binary_id
    field :voile_user_id, Ecto.UUID
    field :guest_name, :string
    field :guest_email, :string

    field :registration_data, :map, default: %{}

    field :status, Ecto.Enum,
      values: [:pending, :approved, :rejected, :waitlisted, :canceled, :no_show],
      default: :pending

    field :registered_at, :utc_datetime
    field :approved_at, :utc_datetime
    field :rejected_at, :utc_datetime
    field :registration_code, :string
    field :amount_paid_idr, :integer, default: 0
    field :paid_at, :utc_datetime
    field :payment_id, :binary_id

    # Note: event_registrations table in atrium does not have inserted_at/updated_at columns
    # so we disable timestamps for this read-only schema.
    timestamps(inserted_at: false, updated_at: false)
  end

  def changeset(registration, attrs) do
    registration
    |> cast(attrs, [
      :event_id,
      :voile_user_id,
      :registration_data,
      :status,
      :registered_at,
      :registration_code,
      :amount_paid_idr
    ])
    |> validate_required([:event_id, :voile_user_id, :registration_code, :registered_at])
    |> unique_constraint(:event_id,
      name: :event_registrations_active_user_unique,
      message: "already registered for this event"
    )
  end
end
