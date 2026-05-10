defmodule Curatorian.PersonalLibrary.BorrowRequest do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @schema_prefix "atrium"
  schema "borrow_requests" do
    field :lender_user_id, Ecto.UUID
    field :borrower_user_id, Ecto.UUID
    field :voile_item_id, Ecto.UUID
    field :item_title, :string

    field :status, Ecto.Enum,
      values: [:pending, :approved, :active, :returned, :rejected, :canceled, :overdue, :dispute],
      default: :pending

    field :request_message, :string
    field :response_message, :string
    field :due_date, :date
    field :borrowed_at, :utc_datetime
    field :returned_at, :utc_datetime
    field :overdue_notified_at, :utc_datetime

    timestamps()
  end

  @required [:lender_user_id, :borrower_user_id, :voile_item_id, :item_title, :status]
  @optional [
    :request_message,
    :response_message,
    :due_date,
    :borrowed_at,
    :returned_at,
    :overdue_notified_at
  ]

  def changeset(request, attrs) do
    request
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:status, [
      "pending",
      "approved",
      "active",
      "returned",
      "rejected",
      "canceled",
      "overdue",
      "dispute"
    ])
  end
end
