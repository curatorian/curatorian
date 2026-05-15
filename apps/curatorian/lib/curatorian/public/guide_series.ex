defmodule Curatorian.Public.GuideSeries do
  @moduledoc "Read-only schema mapping to atrium.guide_series."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "guide_series" do
    field :title, :string
    field :voile_node_id, :integer

    has_many :guides, Curatorian.Public.Guide, foreign_key: :series_id

    timestamps(type: :utc_datetime)
  end
end
