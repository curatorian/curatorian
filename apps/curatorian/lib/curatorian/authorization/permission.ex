defmodule Curatorian.Authorization.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  alias Curatorian.Authorization.{Role, RolePermission}

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "permissions" do
    field :name, :string
    field :slug, :string
    field :resource, :string
    field :action, :string
    field :description, :string

    has_many :role_permissions, RolePermission
    many_to_many :roles, Role, join_through: RolePermission

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :slug, :resource, :action, :description])
    |> validate_required([:name, :slug, :resource, :action])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:slug, min: 2, max: 100)
    |> validate_format(:slug, ~r/^[a-z][a-z0-9_:]*$/,
      message:
        "must start with a letter and contain only lowercase letters, numbers, underscores, and colons"
    )
    |> validate_inclusion(:action, [
      "create",
      "read",
      "update",
      "delete",
      "manage",
      "publish",
      "moderate"
    ])
    |> unique_constraint(:slug)
    |> unique_constraint([:resource, :action])
  end

  @doc """
  Returns a list of valid actions for permissions.
  """
  def valid_actions do
    ["create", "read", "update", "delete", "manage", "publish", "moderate"]
  end
end
