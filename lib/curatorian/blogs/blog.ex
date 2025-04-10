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
