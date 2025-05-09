defmodule Curatorian.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :email, :citext, null: false
      add :username, :citext, null: false
      add :user_type, :string
      add :hashed_password, :string, null: false
      add :confirmed_at, :utc_datetime
      add :last_login, :utc_datetime
      add :last_login_ip, :string

      timestamps(type: :utc_datetime)
    end

    create table(:user_profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :fullname, :string
      add :bio, :string
      add :user_image, :string
      add :social_media, :jsonb
      add :groups, {:array, :string}

      timestamps(type: :utc_datetime)
    end

    create table(:users_tokens) do
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users, [:email, :username])
    create unique_index(:users_tokens, [:context, :token])
  end
end
