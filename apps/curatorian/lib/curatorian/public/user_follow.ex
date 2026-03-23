defmodule Curatorian.Public.UserFollow do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @schema_prefix "atrium"
  schema "user_follows" do
    field :follower_id, Ecto.UUID
    field :following_id, Ecto.UUID

    timestamps(updated_at: false)
  end

  @required [:follower_id, :following_id]

  def changeset(follow, attrs) do
    follow
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> check_constraint(:follower_id, name: :no_self_follow, message: "cannot follow yourself")
    |> unique_constraint([:follower_id, :following_id])
  end
end
