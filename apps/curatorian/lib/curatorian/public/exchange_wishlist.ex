defmodule Curatorian.Public.ExchangeWishlist do
  @moduledoc "Read-only schema for atrium.exchange_wishlists."
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "exchange_wishlists" do
    field :requester_org_page_id, :binary_id
    field :requester_user_id, Ecto.UUID

    field :item_title, :string
    field :item_type, :string
    field :subject_area, :string
    field :description, :string
    field :quantity_needed, :integer

    field :specificity, Ecto.Enum, values: [:specific_title, :subject_area, :format_type, :any]

    field :preferred_province, :string

    field :status, Ecto.Enum, values: [:open, :partially_fulfilled, :fulfilled, :closed]

    field :deleted_at, :utc_datetime

    timestamps()
  end
end
