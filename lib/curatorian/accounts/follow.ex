defmodule Curatorian.Accounts.Follow do
  use Ecto.Schema
  import Ecto.Changeset

  alias Curatorian.Accounts.User

  schema "follows" do
    belongs_to :follower, User
    belongs_to :followed, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:follower_id, :followed_id])
    |> validate_required([:follower_id, :followed_id])
    |> validate_change(:follower_id, fn :follower_id, follower_id ->
      if follower_id == follow.followed_id do
        [
          follower_id: "cannot follow yourself"
        ]
      else
        []
      end
    end)
    |> unique_constraint([:follower_id, :followed_id])
  end
end
