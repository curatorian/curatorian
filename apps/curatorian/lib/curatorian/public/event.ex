defmodule Curatorian.Public.Event do
  @moduledoc "Read-only schema for atrium.events."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "events" do
    field :host_user_id, Ecto.UUID
    field :host_org_page_id, :binary_id

    field :title, :string
    field :slug, :string
    field :description, :string
    field :cover_image_url, :string

    field :event_type, Ecto.Enum,
      values: [:webinar, :seminar, :workshop, :exhibition, :conference, :training, :other]

    field :mode, Ecto.Enum, values: [:online, :offline, :hybrid]

    field :category, Ecto.Enum,
      values: [:library, :archives, :museum, :gallery, :education, :research, :technology, :other]

    field :tags, {:array, :string}, default: []
    field :language, :string, default: "id"

    field :platform, Ecto.Enum, values: [:zoom, :google_meet, :teams, :youtube, :other]

    field :meeting_url, :string
    field :meeting_id, :string
    field :meeting_password, :string

    field :venue_name, :string
    field :venue_address, :string
    field :venue_city, :string
    field :venue_province, :string
    field :venue_maps_url, :string

    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime
    field :timezone, :string, default: "Asia/Jakarta"
    field :duration_minutes, :integer

    field :max_attendees, :integer
    field :registration_opens_at, :utc_datetime
    field :registration_closes_at, :utc_datetime
    field :requires_approval, :boolean, default: false
    field :registration_questions, {:array, :map}, default: []

    field :is_paid, :boolean, default: false
    field :price_idr, :integer, default: 0
    field :early_bird_price_idr, :integer
    field :early_bird_ends_at, :utc_datetime

    field :status, Ecto.Enum,
      values: [:draft, :published, :registration_closed, :ongoing, :completed, :canceled]

    field :recording_url, :string
    field :summary, :string

    field :registration_count, :integer, default: 0
    field :attendance_count, :integer, default: 0
    field :certificate_count, :integer, default: 0

    field :certificate_template_id, :binary_id
    field :auto_issue_certificates, :boolean, default: false
    field :min_attendance_percent, :integer, default: 80

    field :deleted_at, :utc_datetime

    timestamps()
  end
end
