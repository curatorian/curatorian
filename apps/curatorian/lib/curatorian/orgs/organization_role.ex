defmodule Curatorian.Orgs.OrganizationRole do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organization_roles" do
    field :label, :string
    field :slug, :string
    field :description, :string
    field :permissions, {:array, :string}

    timestamps(type: :utc_datetime)
  end

  @roles ~w(owner admin editor member guest)

  @doc false
  def changeset(organization_role, attrs) do
    organization_role
    |> cast(attrs, [:slug, :label, :description, :owner_id])
    |> validate_required([:slug, :label])
    |> validate_inclusion(:slug, @roles)
    |> unique_constraint(:slug)
  end
end
