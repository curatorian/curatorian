defmodule Curatorian.Public.JobApplication do
  @moduledoc "Schema for atrium.job_applications."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "job_applications" do
    field :job_posting_id, :binary_id
    field :voile_user_id, Ecto.UUID

    field :cover_letter, :string
    field :cv_url, :string

    field :status, Ecto.Enum,
      values: [:pending, :reviewed, :shortlisted, :rejected, :hired],
      default: :pending

    field :notes, :string
    field :applied_at, :utc_datetime
    field :reviewed_at, :utc_datetime
    field :reviewed_by, Ecto.UUID

    timestamps()
  end

  @required [:job_posting_id, :voile_user_id, :applied_at]
  @optional [:cover_letter, :cv_url, :status, :notes, :reviewed_at, :reviewed_by]

  def changeset(application, attrs) do
    application
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> unique_constraint([:job_posting_id, :voile_user_id],
      name: :job_applications_job_posting_id_voile_user_id_index,
      message: "sudah melamar ke lowongan ini"
    )
  end
end
