defmodule Curatorian.Orgs.OrganizationRole do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organization_roles" do
    field :label, :string
    field :slug, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organization_role, attrs) do
    organization_role
    |> cast(attrs, [:slug, :label])
    |> validate_required([:slug, :label])
    |> unique_constraint(:slug)
  end
end
