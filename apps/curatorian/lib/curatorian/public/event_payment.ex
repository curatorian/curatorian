defmodule Curatorian.Public.EventPayment do
  @moduledoc "Read-only schema for atrium.event_payments."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "event_payments" do
    field :event_id, :binary_id
    field :registration_id, :binary_id
    field :voile_user_id, Ecto.UUID

    field :gross_amount_idr, :integer
    field :platform_fee_idr, :integer
    field :net_amount_idr, :integer

    field :gateway_order_id, :string
    field :gateway_transaction_id, :string
    field :payment_method, :string

    field :status, Ecto.Enum,
      values: [:pending, :success, :failed, :refunded, :expired],
      default: :pending

    field :paid_at, :utc_datetime
    field :refunded_at, :utc_datetime
    field :refund_reason, :string

    timestamps()
  end
end
