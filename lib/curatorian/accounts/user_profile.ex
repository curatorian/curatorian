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
    field :groups, {:array, :string}

    belongs_to :user, Curatorian.Accounts.User, type: :binary_id

    field :twitter, :string, virtual: true
    field :facebook, :string, virtual: true
    field :linkedin, :string, virtual: true
    field :instagram, :string, virtual: true
    field :website, :string, virtual: true

    embeds_many :educations, Curatorian.Accounts.Education, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def changeset(user_profile, attrs) do
    user_profile
    |> cast(attrs, [
      :user_id,
      :fullname,
      :bio,
      :user_image,
      :twitter,
      :facebook,
      :linkedin,
      :instagram,
      :website,
      :groups
    ])
    |> cast_embed(:educations, with: &Curatorian.Accounts.Education.changeset/2)
    |> validate_required([:user_id])
    |> put_social_media
    |> foreign_key_constraint(:user_id)
    |> cast_assoc(:user)
  end

  defp put_social_media(changeset) do
    twitter = get_field(changeset, :twitter)
    facebook = get_field(changeset, :facebook)
    linkedin = get_field(changeset, :linkedin)
    instagram = get_field(changeset, :instagram)
    website = get_field(changeset, :website)

    social_media = %{
      "twitter" => twitter,
      "facebook" => facebook,
      "linkedin" => linkedin,
      "instagram" => instagram,
      "website" => website
    }

    put_change(changeset, :social_media, social_media)
  end
end
