defmodule Curatorian.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :status, :string, default: "pending"
      add :type, :string
      add :description, :string
      add :image_logo, :string
      add :image_cover, :string
      add :owner_id, references(:users, type: :binary_id, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:organizations, [:slug])
    create index(:organizations, [:status])
    create index(:organizations, [:owner_id])
  end
end
