defmodule Curatorian.Public.ExchangeOffer do
  @moduledoc "Read-only schema for atrium.exchange_offers."
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "exchange_offers" do
    field :offeror_org_page_id, :binary_id
    field :offeror_user_id, Ecto.UUID

    field :catalog_collection_id, :string

    field :item_title, :string
    field :item_type, :string
    field :item_description, :string
    field :item_quantity, :integer

    field :item_condition, Ecto.Enum, values: [:new, :very_good, :good, :fair, :poor]

    field :suitability_note, :string

    field :available_province, :string
    field :available_city, :string

    field :status, Ecto.Enum, values: [:available, :reserved, :matched, :transferred, :withdrawn]

    field :deleted_at, :utc_datetime

    timestamps()
  end
end
