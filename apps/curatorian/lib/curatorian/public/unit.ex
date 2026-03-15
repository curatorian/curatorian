defmodule Curatorian.Public.Unit do
  @moduledoc "Read-only schema for voile.nodes (organization units)."

  use Ecto.Schema

  @primary_key {:id, :id, autogenerate: false}
  @schema_prefix "voile"

  schema "nodes" do
    field :name, :string
    field :abbr, :string
    field :image, :string

    timestamps(type: :utc_datetime)
  end
end
