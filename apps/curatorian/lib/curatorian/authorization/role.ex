defmodule Curatorian.Authorization.Role do
  use Ecto.Schema
  import Ecto.Changeset

  alias Curatorian.Accounts.User
  alias Curatorian.Authorization.{Permission, RolePermission}

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "roles" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :is_system_role, :boolean, default: false
    field :priority, :integer, default: 0

    has_many :users, User
    has_many :role_permissions, RolePermission
    many_to_many :permissions, Permission, join_through: RolePermission

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :slug, :description, :is_system_role, :priority])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 2, max: 50)
    |> validate_length(:slug, min: 2, max: 50)
    |> validate_format(:slug, ~r/^[a-z][a-z0-9_]*$/,
      message:
        "must start with a letter and contain only lowercase letters, numbers, and underscores"
    )
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
    |> validate_number(:priority, greater_than_or_equal_to: 0)
  end

  @doc """
  Changeset for system roles that should not be edited by users.
  """
  def system_role_changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :slug, :description, :priority])
    |> put_change(:is_system_role, true)
    |> validate_required([:name, :slug])
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end
end
