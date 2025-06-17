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
    |> cast(attrs, [:user_id, :organization_id, :organization_role_id, :joined_at])
    |> validate_required([:user_id, :organization_id, :organization_role_id])
    |> unique_constraint(:user_id, name: :unique_org_membership)
    |> foreign_key_constraint(:organization_role_id)
    |> put_change(:joined_at, attrs[:joined_at] || DateTime.utc_now())
  end
end
