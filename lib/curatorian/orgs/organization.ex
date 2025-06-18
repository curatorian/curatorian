defmodule Curatorian.Orgs.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  alias Curatorian.Orgs.OrganizationUser
  alias Curatorian.Accounts.User

  schema "organizations" do
    field :name, :string
    field :status, :string, default: "draft"
    field :type, :string
    field :description, :string
    field :slug, :string
    field :image_logo, :string
    field :image_cover, :string

    belongs_to :owner, User
    has_many :organization_users, OrganizationUser
    has_many :users, through: [:organization_users, :user]

    timestamps(type: :utc_datetime)
  end

  @statuses ~w(draft pending approved archived)
  @types ~w(company institution community non_profit)

  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [
      :name,
      :slug,
      :status,
      :type,
      :description,
      :image_logo,
      :image_cover,
      :owner_id
    ])
    |> validate_required([:name, :slug, :owner_id])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:type, @types)
    |> validate_format(:slug, ~r/^[a-z0-9\-]+$/,
      message: "must be lowercase alphanumeric with hyphens"
    )
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:owner_id)
    |> validate_owner_exists()
  end

  defp validate_owner_exists(changeset) do
    if get_field(changeset, :owner_id) do
      changeset
    else
      add_error(changeset, :owner_id, "must have an owner")
    end
  end
end
