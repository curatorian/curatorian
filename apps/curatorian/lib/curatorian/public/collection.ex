defmodule Curatorian.Public.Collection do
  @moduledoc "Read-only schema for voile.collections."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "voile"

  schema "collections" do
    field :title, :string
    field :description, :string
    field :collection_code, :string
    field :status, :string, default: "draft"
    field :access_level, :string, default: "private"
    field :collection_type, :string
    field :thumbnail, :string

    belongs_to :unit, Curatorian.Public.Unit, type: :integer

    has_many :collection_fields, Voile.Schema.Catalog.CollectionField, foreign_key: :collection_id

    has_many :items, Voile.Schema.Catalog.Item, foreign_key: :collection_id

    timestamps(type: :utc_datetime)
  end
end
