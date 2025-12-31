defmodule Curatorian.Authorization.RolePermission do
  use Ecto.Schema
  import Ecto.Changeset

  alias Curatorian.Authorization.{Role, Permission}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "role_permissions" do
    belongs_to :role, Role, type: :binary_id
    belongs_to :permission, Permission, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role_permission, attrs) do
    role_permission
    |> cast(attrs, [:role_id, :permission_id])
    |> validate_required([:role_id, :permission_id])
    |> foreign_key_constraint(:role_id)
    |> foreign_key_constraint(:permission_id)
    |> unique_constraint([:role_id, :permission_id])
  end
end
