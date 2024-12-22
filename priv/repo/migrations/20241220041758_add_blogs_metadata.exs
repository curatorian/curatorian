defmodule Curatorian.Repo.Migrations.AddBlogsMetadata do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :string
      timestamps()
    end

    create table(:categories) do
      add :name, :string
      timestamps()
    end

    create table(:blogs_tags, primary_key: false) do
      add :blog_id, references(:blogs, type: :binary_id)
      add :tag_id, references(:tags)
    end

    create table(:blogs_categories, primary_key: false) do
      add :blog_id, references(:blogs, type: :binary_id)
      add :category_id, references(:categories)
    end

    create unique_index(:tags, [:name])
    create unique_index(:categories, [:name])
    create index(:blogs_tags, [:blog_id])
    create index(:blogs_tags, [:tag_id])
    create index(:blogs_categories, [:blog_id])
    create index(:blogs_categories, [:category_id])
  end
end
