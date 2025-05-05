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

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organizations, [:slug])
  end
end
