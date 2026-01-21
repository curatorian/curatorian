defmodule Curatorian.Repo.Migrations.CreateRbacTables do
  use Ecto.Migration

  def change do
    # Roles table
    create table(:roles, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :is_system_role, :boolean, default: false
      add :priority, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:roles, [:name])
    create unique_index(:roles, [:slug])
    create index(:roles, [:priority])

    # Permissions table
    create table(:permissions, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :name, :string, null: false
      add :slug, :string, null: false
      add :resource, :string, null: false
      add :action, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:permissions, [:slug])
    create unique_index(:permissions, [:resource, :action])
    create index(:permissions, [:resource])

    # Role Permissions join table
    create table(:role_permissions, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :role_id, references(:roles, type: :binary_id, on_delete: :delete_all), null: false

      add :permission_id, references(:permissions, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:role_permissions, [:role_id, :permission_id])
    create index(:role_permissions, [:role_id])
    create index(:role_permissions, [:permission_id])

    # Add role_id to users table
    alter table(:users) do
      add :role_id, references(:roles, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:users, [:role_id])
  end
end
