defmodule Curatorian.Public.EventRegistration do
  @moduledoc "Schema for atrium.event_registrations (read + write from Curatorian)."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @schema_prefix "atrium"

  schema "event_registrations" do
    field :event_id, :binary_id
    field :voile_user_id, Ecto.UUID
    field :guest_name, :string
    field :guest_email, :string

    field :registration_data, :map, default: %{}

    field :status, Ecto.Enum,
      values: [:pending, :approved, :rejected, :waitlisted, :canceled, :no_show],
      default: :pending

    field :registered_at, :utc_datetime
    field :approved_at, :utc_datetime
    field :rejected_at, :utc_datetime
    field :registration_code, :string
    field :token, :string
    field :consented_at, :utc_datetime
    field :confirmation_sent_at, :utc_datetime
    field :amount_paid_idr, :integer, default: 0
    field :paid_at, :utc_datetime
    field :payment_id, :binary_id

    # Note: event_registrations table in atrium does not have inserted_at/updated_at columns
    # so we disable timestamps for this read-only schema.
    timestamps(inserted_at: false, updated_at: false)
  end

  def changeset(registration, attrs) do
    registration
    |> cast(attrs, [
      :event_id,
      :voile_user_id,
      :guest_name,
      :guest_email,
      :registration_data,
      :status,
      :registered_at,
      :registration_code,
      :amount_paid_idr,
      # Server-set in register_for_event (never client params): the /r/:token
      # page and the consent timestamp. Without casting these the generated
      # token was silently dropped and participants could never reach their
      # participant page.
      :token,
      :consented_at
    ])
    |> validate_required([:event_id, :registration_code, :registered_at])
    |> validate_identity()
    |> validate_format(:guest_email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/,
      message: "must be a valid email address"
    )
    |> unique_constraint(:event_id,
      name: :event_registrations_active_user_unique,
      message: "already registered for this event"
    )
    |> unique_constraint(:event_id,
      name: :event_registrations_active_guest_unique,
      message: "already registered for this event"
    )
    |> unique_constraint(:token)
    |> unique_constraint(:registration_code)
  end

  # Mirrors the DB check constraint `event_registrant_identity`: exactly one
  # of an account id or a guest (name + email) — never both, never neither.
  defp validate_identity(changeset) do
    user_id = get_field(changeset, :voile_user_id)
    guest_name = get_field(changeset, :guest_name)
    guest_email = get_field(changeset, :guest_email)

    cond do
      user_id && (guest_name || guest_email) ->
        add_error(changeset, :voile_user_id, "cannot be set together with a guest identity")

      user_id ->
        changeset

      guest_name && guest_email ->
        changeset

      guest_email ->
        add_error(changeset, :guest_name, "guest name is required with a guest email")

      guest_name ->
        add_error(changeset, :guest_email, "guest email is required with a guest name")

      true ->
        add_error(changeset, :voile_user_id, "must provide an account or a guest identity")
    end
  end
end
