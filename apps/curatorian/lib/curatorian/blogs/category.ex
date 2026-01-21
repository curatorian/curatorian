defmodule Curatorian.Blogs.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :slug, :string
    field :description, :string

    many_to_many :blogs, Curatorian.Blogs.Blog,
      join_through: "blogs_categories",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :slug, :description])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
  end
end
