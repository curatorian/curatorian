defmodule Curatorian.Orgs.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  alias Curatorian.Orgs.OrganizationUser

  schema "organizations" do
    field :name, :string
    field :status, :string
    field :type, :string
    field :description, :string
    field :slug, :string
    field :image_logo, :string
    field :image_cover, :string

    has_many :organization_users, OrganizationUser
    has_many :users, through: [:organization_users, :user]

    timestamps(type: :utc_datetime)
  end

  @statuses ~w(draft pending approved archived)

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:name, :slug, :status, :type, :description, :image_logo, :image_cover])
    |> validate_required([:name, :slug, :status])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:slug)
  end
end
