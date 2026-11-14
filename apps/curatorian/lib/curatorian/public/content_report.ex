defmodule Curatorian.Public.ContentReport do
  @moduledoc "Schema for atrium.content_reports (read + write from Curatorian)."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @schema_prefix "atrium"

  schema "content_reports" do
    field :reporter_id, Ecto.UUID

    field :content_type, Ecto.Enum,
      values: [
        :user_profile,
        :org_page,
        :org_post,
        :event,
        :direct_message,
        :borrow_request,
        :blog_post,
        :blog_comment
      ]

    field :content_id, :binary_id

    field :reason, Ecto.Enum,
      values: [:spam, :harassment, :inappropriate, :fake, :copyright, :other]

    field :details, :string

    field :status, Ecto.Enum,
      values: [:pending, :reviewed, :actioned, :dismissed],
      default: :pending

    timestamps(updated_at: false)
  end

  def changeset(report, attrs) do
    report
    |> cast(attrs, [:reporter_id, :content_type, :content_id, :reason, :details, :status])
    |> validate_required([:reporter_id, :content_type, :content_id, :reason])
  end
end
