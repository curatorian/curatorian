defmodule Curatorian.Public.BlogPost do
  @moduledoc "Read-only schema for atrium.user_blog_posts."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "user_blog_posts" do
    field :voile_user_id, Ecto.UUID
    field :title, :string
    field :slug, :string
    field :body, :string
    field :cover_url, :string
    field :tags, {:array, :string}, default: []
    field :status, :string
    field :published_at, :utc_datetime
    field :view_count, :integer, default: 0
    field :comment_count, :integer, default: 0
    field :is_comments_enabled, :boolean, default: true
    field :deleted_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end
end
