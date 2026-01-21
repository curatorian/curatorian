defmodule Curatorian.Repo.Migrations.CreateOrganizationUsers do
  use Ecto.Migration

  def change do
    create table(:organization_users) do
      add :joined_at, :utc_datetime, null: false, default: fragment("NOW()")
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false

      add :organization_role_id, references(:organization_roles, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organization_users, [:user_id, :organization_id],
             name: :unique_org_membership
           )

    create index(:organization_users, [:user_id])
    create index(:organization_users, [:organization_id])
    create index(:organization_users, [:organization_role_id])
  end
end
