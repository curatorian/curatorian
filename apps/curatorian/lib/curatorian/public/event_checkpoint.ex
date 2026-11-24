defmodule Curatorian.Public.EventCheckpoint do
  @moduledoc "Read-only schema for atrium.event_checkpoints (organizer-defined session codes)."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "event_checkpoints" do
    field :event_id, :binary_id
    field :label, :string
    field :code, :string
    field :opens_at, :utc_datetime
    field :closes_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end
end
