defmodule Curatorian.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "comments" do
    field :content, :string
    belongs_to :blog, Curatorian.Blogs.Blog, type: :binary_id
    belongs_to :user, Curatorian.Accounts.User, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end
