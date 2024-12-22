defmodule Curatorian.Repo.Migrations.CreateBlogs do
  use Ecto.Migration

  def change do
    create table(:blogs, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :title, :string
      add :slug, :string
      add :content, :text
      add :summary, :string
      add :image_url, :string
      add :status, :string
      add :user_id, references(:users, type: :binary_id, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:blogs, [:slug])
    create index(:blogs, [:user_id])
  end
end
