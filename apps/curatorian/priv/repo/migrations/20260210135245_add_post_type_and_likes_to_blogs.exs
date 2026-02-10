defmodule Curatorian.Repo.Migrations.AddPostTypeAndLikesToBlogs do
  use Ecto.Migration

  def change do
    alter table(:blogs) do
      add :post_type, :string, default: "blog", null: false
      add :likes_count, :integer, default: 0, null: false
    end

    create index(:blogs, [:post_type])
    create index(:blogs, [:status])
  end
end
