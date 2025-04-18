defmodule Curatorian.Accounts.Education do
  use Ecto.Schema
  import Ecto.Changeset

  alias Curatorian.Accounts.UserProfile

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "educations" do
    field :school, :string
    field :degree, :string
    field :field_of_study, :string
    field :graduation_year, :integer
    field :start_date, :date
    field :end_date, :date
    field :grade, :string
    field :description, :string

    belongs_to :user_profile, UserProfile, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  def changeset(education, attrs) do
    education
    |> cast(attrs, [
      :id,
      :school,
      :degree,
      :field_of_study,
      :graduation_year,
      :start_date,
      :end_date,
      :grade,
      :description
    ])
    |> validate_required([:school, :degree, :field_of_study, :graduation_year],
      message: "Wajib diisi!"
    )
    |> foreign_key_constraint(:user_profile_id)
  end
end
