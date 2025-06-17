defmodule Curatorian.Accounts.UserProfile do
  use Ecto.Schema
  import Ecto.Changeset

  alias Curatorian.Accounts.User
  alias Curatorian.Accounts.Education

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "user_profiles" do
    field :fullname, :string
    field :bio, :string
    field :user_image, :string
    field :cover_image, :string
    field :social_media, :map, type: :jsonb
    field :groups, {:array, :string}
    field :job_title, :string
    field :company, :string
    field :location, :string
    field :phone_number, :string
    field :birthday, :date
    field :gender, :string

    belongs_to :user, User, type: :binary_id

    has_many :educations, Education,
      foreign_key: :user_profile_id,
      on_delete: :delete_all,
      on_replace: :delete

    field :twitter, :string, virtual: true
    field :facebook, :string, virtual: true
    field :linkedin, :string, virtual: true
    field :instagram, :string, virtual: true
    field :website, :string, virtual: true

    timestamps(type: :utc_datetime)
  end

  def changeset(user_profile, attrs) do
    user_profile
    |> cast(attrs, [
      :user_id,
      :fullname,
      :bio,
      :user_image,
      :cover_image,
      :company,
      :job_title,
      :location,
      :phone_number,
      :birthday,
      :gender,
      :twitter,
      :facebook,
      :linkedin,
      :instagram,
      :website,
      :groups
    ])
    |> validate_required([:user_id])
    |> put_social_media
    |> foreign_key_constraint(:user_id)
    |> cast_assoc(:user)
    |> cast_assoc(:educations, with: &Curatorian.Accounts.Education.changeset/2)
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
