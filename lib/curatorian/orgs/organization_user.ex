defmodule Curatorian.Orgs.OrganizationUser do
  use Ecto.Schema
  import Ecto.Changeset

  alias Curatorian.Accounts.User
  alias Curatorian.Orgs.Organization
  alias Curatorian.Orgs.OrganizationRole

  schema "organization_users" do
    field :joined_at, :utc_datetime
    belongs_to :user, User
    belongs_to :organization, Organization
    belongs_to :organization_role, OrganizationRole

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organization_user, attrs) do
    organization_user
    |> cast(attrs, [:user_id, :organization_id, :role_id, :joined_at])
    |> validate_required([:user_id, :organization_id, :role_id])
    |> unique_constraint(:user_id, name: :unique_org_membership)
  end
end
