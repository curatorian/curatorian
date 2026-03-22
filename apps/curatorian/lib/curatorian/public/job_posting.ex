defmodule Curatorian.Public.JobPosting do
  @moduledoc "Read-only schema for atrium.job_postings."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "job_postings" do
    field :host_org_page_id, :binary_id
    field :host_user_id, Ecto.UUID

    field :title, :string
    field :slug, :string
    field :institution_name, :string
    field :description, :string
    field :requirements, :string

    field :employment_type, Ecto.Enum,
      values: [:full_time, :part_time, :volunteer, :magang, :contract, :freelance]

    field :category, Ecto.Enum,
      values: [:library, :archives, :museum, :gallery, :education, :research, :technology, :other]

    field :location_type, Ecto.Enum, values: [:onsite, :remote, :hybrid]
    field :location_city, :string
    field :location_province, :string

    field :salary_visible, :boolean, default: false
    field :salary_negotiable, :boolean, default: false
    field :salary_min_idr, :integer
    field :salary_max_idr, :integer

    field :application_method, Ecto.Enum, values: [:in_platform, :external_link]
    field :application_url, :string
    field :application_deadline, :utc_datetime
    field :application_count, :integer, default: 0

    field :status, Ecto.Enum,
      values: [:draft, :active, :filled, :expired, :closed],
      default: :draft

    field :is_featured, :boolean, default: false
    field :posted_at, :utc_datetime
    field :deleted_at, :utc_datetime

    timestamps()
  end
end
