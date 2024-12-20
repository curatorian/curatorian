defmodule Curatorian.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :content, :text
      add :blog_id, references(:blogs, type: :uuid, on_delete: :nothing)
      add :user_id, references(:users, type: :uuid, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:blog_id])
    create index(:comments, [:user_id])
  end
end
