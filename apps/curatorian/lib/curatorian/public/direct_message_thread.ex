defmodule Curatorian.Public.DirectMessageThread do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @schema_prefix "atrium"
  schema "direct_message_threads" do
    field :participant_a_id, Ecto.UUID
    field :participant_b_id, Ecto.UUID

    field :last_message_preview, :string
    field :last_message_at, :utc_datetime
    field :last_message_by, Ecto.UUID

    field :unread_count_a, :integer, default: 0
    field :unread_count_b, :integer, default: 0

    timestamps()
  end

  @required [:participant_a_id, :participant_b_id]
  @optional [
    :last_message_preview,
    :last_message_at,
    :last_message_by,
    :unread_count_a,
    :unread_count_b
  ]

  def changeset(thread, attrs) do
    thread
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> check_constraint(:participant_a_id,
      name: :participants_sorted,
      message: "participant_a_id must be less than participant_b_id"
    )
    |> unique_constraint([:participant_a_id, :participant_b_id])
  end
end
