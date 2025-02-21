defmodule Curatorian.Accounts.Education do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :school, :string
    field :degree, :string
    field :field_of_study, :string
    field :start_date, :utc_datetime
    field :end_date, :utc_datetime
    field :grade, :string
    field :description, :string
  end

  def changeset(education, attrs) do
    education
    |> cast(attrs, [
      :school,
      :degree,
      :field_of_study,
      :start_date,
      :end_date,
      :grade,
      :description
    ])
    |> validate_required([
      :school,
      :degree,
      :field_of_study,
      :start_date,
      :end_date
    ])
  end
end
