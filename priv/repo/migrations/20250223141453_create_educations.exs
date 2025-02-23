defmodule Curatorian.Repo.Migrations.CreateEducations do
  use Ecto.Migration

  def change do
    create table(:educations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :school, :string, null: false
      add :degree, :string, null: false
      add :field_of_study, :string, null: false
      add :graduation_year, :integer, null: false
      add :start_date, :date
      add :end_date, :date
      add :grade, :string
      add :description, :text

      add :user_profile_id, references(:user_profiles, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end
  end
end
