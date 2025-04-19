defmodule Curatorian.Blogs.Blog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "blogs" do
    field :status, :string
    field :title, :string
    field :slug, :string
    field :content, :string
    field :summary, :string
    field :image_url, :string
    belongs_to :user, Curatorian.Accounts.User, type: :binary_id

    many_to_many :categories, Curatorian.Blogs.Category,
      join_through: "blogs_categories",
      on_replace: :delete

    many_to_many :tags, Curatorian.Blogs.Tag,
      join_through: "blogs_tags",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(blog, attrs) do
    blog
    |> cast(attrs, [:title, :slug, :content, :summary, :image_url, :status, :user_id])
    |> validate_required([:title, :slug, :content, :summary, :status, :user_id])
    |> validate_length(:summary, max: 200)
    |> unique_constraint(:slug)
  end
end
