defmodule Curatorian.Public.EventCheckpointRecord do
  @moduledoc """
  Schema for atrium.event_checkpoint_records (read + write from Curatorian).

  Written directly by Curatorian: the public participant page (`/r/:token`)
  is where webinar attendees enter session codes — Atrium has no public
  endpoint for it.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @schema_prefix "atrium"

  schema "event_checkpoint_records" do
    field :registration_id, :binary_id
    field :checkpoint_id, :binary_id
    field :recorded_at, :utc_datetime

    belongs_to :checkpoint, Curatorian.Public.EventCheckpoint,
      foreign_key: :checkpoint_id,
      define_field: false

    timestamps(inserted_at: false, updated_at: false)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:registration_id, :checkpoint_id, :recorded_at])
    |> validate_required([:registration_id, :checkpoint_id, :recorded_at])
    |> unique_constraint([:registration_id, :checkpoint_id])
  end
end
