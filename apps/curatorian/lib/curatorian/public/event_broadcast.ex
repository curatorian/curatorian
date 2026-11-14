defmodule Curatorian.Public.EventBroadcast do
  @moduledoc """
  Read-only mirror of atrium.event_broadcasts — announcements shown on the
  public event page.
  """

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @schema_prefix "atrium"
  schema "event_broadcasts" do
    field :event_id, :binary_id
    field :title, :string
    field :body, :string
    field :notify_participants, :boolean
    field :created_by, :binary_id

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
