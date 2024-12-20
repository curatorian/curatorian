defmodule Curatorian.Accounts.UserProfile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "user_profiles" do
    field :fullname, :string
    field :bio, :string
    field :user_image, :string
    field :social_media, :map, type: :jsonb
    field :educations, :map, type: :jsonb
    field :groups, {:array, :string}

    belongs_to :user, Curatorian.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:fullname, :bio, :user_image, :social_media, :educations, :groups])
    |> validate_required([:fullname])
    |> foreign_key_constraint(:user_id)
  end
end
