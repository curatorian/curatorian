defmodule Curatorian.Public.EventCertificateTemplate do
  @moduledoc """
  Read-only schema for `atrium.event_certificate_templates`.

  Certificate templates are authored in Atrium's designer. Curatorian only
  reads them to render the issued certificate (background, positioned fields,
  signatory block), so this module deliberately has no changesets.
  """

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @timestamps_opts false
  @schema_prefix "atrium"

  schema "event_certificate_templates" do
    field :org_page_id, :binary_id
    field :voile_user_id, Ecto.UUID

    field :name, :string
    field :is_default, :boolean, default: false

    field :background_image_url, :string
    field :background_color, :string, default: "#FFFFFF"
    field :layout_config, :map, default: %{}
    field :font_family, :string, default: "Playfair Display"

    field :signature_name, :string
    field :signature_title, :string
    field :signature_image_url, :string

    field :show_event_title, :boolean, default: true
    field :show_host_name, :boolean, default: true
    field :show_date, :boolean, default: true
    field :show_duration, :boolean, default: true
    field :show_cert_number, :boolean, default: true
    field :show_verification_qr, :boolean, default: true

    field :preview_url, :string
    field :deleted_at, :utc_datetime

    # Read-only, but present so fixtures/tests can insert complete rows.
    field :inserted_at, :utc_datetime
    field :updated_at, :utc_datetime
  end
end
