defmodule Curatorian.Public.Guide do
  @moduledoc "Read-only schema for atrium.guides."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "guides" do
    field :voile_user_id, Ecto.UUID
    field :voile_node_id, :integer
    field :title, :string
    field :slug, :string
    field :description, :string
    field :cover_url, :string
    field :content, :string
    field :content_html, :string
    field :category, :string
    field :guide_type, :string
    field :difficulty, :string
    field :estimated_read_minutes, :integer
    field :tags, {:array, :string}, default: []
    field :order_position, :integer, default: 0
    field :status, :string
    field :is_featured, :boolean, default: false
    field :view_count, :integer, default: 0
    field :published_at, :utc_datetime
    field :deleted_at, :utc_datetime

    belongs_to :series, Curatorian.Public.GuideSeries,
      foreign_key: :series_id,
      type: :binary_id

    field :series_position, :integer

    timestamps(type: :utc_datetime)
  end
end
