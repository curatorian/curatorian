defmodule Curatorian.Public.Role do
  @moduledoc "Read-only schema for atrium.roles."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "roles" do
    field :name, :string
    field :scope, :string
    field :is_system, :boolean

    timestamps()
  end
end
