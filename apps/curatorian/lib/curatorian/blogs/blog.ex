defmodule Curatorian.Blogs.Blog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "blogs" do
    field :status, :string, default: "published"
    field :title, :string
    field :slug, :string
    field :content, :string
    field :summary, :string
    field :image_url, :string
    # "blog" or "post"
    field :post_type, :string, default: "blog"
    field :likes_count, :integer, default: 0
    belongs_to :user, Voile.Schema.Accounts.User, type: :binary_id

    many_to_many :categories, Curatorian.Blogs.Category,
      join_through: "blogs_categories",
      on_replace: :delete

    many_to_many :tags, Curatorian.Blogs.Tag,
      join_through: "blogs_tags",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(blog, attrs, tags \\ []) do
    blog
    |> cast(attrs, [:title, :slug, :content, :summary, :image_url, :status, :post_type, :user_id])
    |> validate_required([:content, :status, :post_type, :user_id])
    |> validate_inclusion(:post_type, ["blog", "post"])
    |> validate_inclusion(:status, ["draft", "published"])
    |> validate_post_type_requirements()
    |> unique_constraint(:slug)
    |> put_assoc(:tags, tags)
  end

  defp validate_post_type_requirements(changeset) do
    post_type = get_field(changeset, :post_type)

    case post_type do
      "blog" ->
        changeset
        |> validate_required([:title, :slug, :summary])
        |> validate_length(:summary, max: 200)

      "post" ->
        changeset
        |> validate_length(:content, max: 500)
        |> put_change(:title, nil)
        |> put_change(:slug, nil)
        |> put_change(:summary, nil)

      _ ->
        changeset
    end
  end
end
