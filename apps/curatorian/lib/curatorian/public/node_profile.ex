defmodule Curatorian.Public.NodeProfile do
  @moduledoc "Read-only schema for atrium.node_profiles joined with voile.nodes."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "node_profiles" do
    field :voile_node_id, :integer
    field :node_type, Ecto.Enum, values: [:organization, :personal, :consortium]
    field :institution_type, Ecto.Enum, values: [:library, :museum, :gallery, :archive]
    field :institution_name, :string
    field :city, :string
    field :province, :string
    field :website, :string
    field :phone, :string
    field :address, :string
    field :listed_in_directory, :boolean, default: false
    field :status, Ecto.Enum, values: [:pending, :approved, :rejected], default: :pending
    field :deleted_at, :utc_datetime

    belongs_to :node, Curatorian.Public.Unit,
      foreign_key: :voile_node_id,
      references: :id,
      define_field: false,
      type: :integer

    timestamps()
  end
end
