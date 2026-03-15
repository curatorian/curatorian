defmodule Curatorian.Public.BlogPostComment do
  @moduledoc "Schema for atrium.blog_post_comments — used for both reading and creating comments."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "blog_post_comments" do
    field :blog_post_id, :binary_id
    field :voile_user_id, Ecto.UUID
    field :author_username, :string
    field :author_display_name, :string
    field :author_avatar_url, :string
    field :body, :string
    field :is_hidden, :boolean, default: false
    field :deleted_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @required [:blog_post_id, :voile_user_id, :author_username, :author_display_name, :body]
  @optional [:author_avatar_url, :is_hidden, :deleted_at]

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_length(:body, min: 1, max: 5000)
  end
end
