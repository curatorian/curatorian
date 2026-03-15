defmodule Curatorian.Public.UserProfile do
  @moduledoc "Read-only schema for atrium.user_profiles."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "user_profiles" do
    field :voile_user_id, Ecto.UUID
    field :voile_node_id, :integer

    field :username, :string
    field :display_name, :string
    field :headline, :string
    field :bio, :string
    field :avatar_url, :string
    field :cover_url, :string

    field :current_position, :string
    field :current_institution, :string
    field :institution_type, :string
    field :years_experience, :integer
    field :city, :string
    field :province, :string

    field :education, {:array, :map}, default: []
    field :certifications, {:array, :map}, default: []
    field :social_links, :map, default: %{}

    field :is_public, :boolean, default: true
    field :follower_count, :integer, default: 0
    field :following_count, :integer, default: 0
    field :webinar_hosted_count, :integer, default: 0
    field :webinar_attended_count, :integer, default: 0
    field :is_verified, :boolean, default: false
    field :verified_at, :utc_datetime
    field :deleted_at, :utc_datetime

    timestamps()
  end
end
