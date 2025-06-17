defmodule Curatorian.Repo.Migrations.CreateOrganizationRoles do
  use Ecto.Migration

  def change do
    create table(:organization_roles) do
      add :slug, :string
      add :label, :string
      add :description, :string
      add :permissions, {:array, :string}, default: []
      add :owner_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organization_roles, [:slug])
    create index(:organization_roles, [:owner_id])

    # Create default roles
    execute """
    INSERT INTO organization_roles (slug, label, inserted_at, updated_at)
    VALUES
      ('owner', 'Owner', NOW(), NOW()),
      ('admin', 'Admin', NOW(), NOW()),
      ('editor', 'Editor', NOW(), NOW()),
      ('member', 'Member', NOW(), NOW()),
      ('guest', 'Guest', NOW(), NOW())
    ON CONFLICT (slug) DO NOTHING
    """
  end
end
