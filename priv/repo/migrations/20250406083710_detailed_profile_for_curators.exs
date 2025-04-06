defmodule Curatorian.Repo.Migrations.DetailedProfileForCurators do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :is_verified, :boolean, default: false
      add :is_private, :boolean, default: false
      add :user_role, :string, default: "curator"
    end

    alter table("user_profiles") do
      add :cover_image, :string
      add :job_title, :string
      add :company, :string
      add :location, :string
      add :phone_number, :string
      add :website, :string
      add :birthday, :date
      add :gender, :string
    end
  end
end
