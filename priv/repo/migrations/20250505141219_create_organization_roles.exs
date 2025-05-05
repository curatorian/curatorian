defmodule Curatorian.Repo.Migrations.CreateOrganizationRoles do
  use Ecto.Migration

  def change do
    create table(:organization_roles) do
      add :slug, :string
      add :label, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organization_roles, [:slug])
  end
end
