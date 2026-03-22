defmodule Curatorian.Public.EventAttendance do
  @moduledoc "Read-only schema for atrium.event_attendances."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "event_attendances" do
    field :event_id, :binary_id
    field :registration_id, :binary_id
    field :voile_user_id, Ecto.UUID
    field :check_in_method, Ecto.Enum, values: [:qr_scan, :manual, :self_checkin]
    field :checked_in_at, :utc_datetime
    field :checked_in_by, Ecto.UUID
    field :checked_out_at, :utc_datetime
    field :duration_minutes, :integer
    field :is_eligible_for_cert, :boolean, default: false

    timestamps(updated_at: false)
  end
end
