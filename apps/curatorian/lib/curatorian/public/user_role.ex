defmodule Curatorian.Public.UserRole do
  @moduledoc "Read-only schema for atrium.user_roles."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "user_roles" do
    field :voile_user_id, Ecto.UUID
    field :voile_node_id, :integer
    field :role_id, :binary_id
    field :membership_type, Ecto.Enum, values: [:primary, :guest]
    field :status, Ecto.Enum, values: [:active, :pending, :revoked]
    field :expires_at, :utc_datetime

    timestamps()
  end
end
