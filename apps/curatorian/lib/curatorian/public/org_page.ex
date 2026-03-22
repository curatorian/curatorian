defmodule Curatorian.Public.OrgPage do
  @moduledoc "Read-only schema for atrium.org_pages."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "org_pages" do
    field :voile_node_id, :integer

    field :slug, :string
    field :name, :string
    field :tagline, :string
    field :description, :string

    field :category, Ecto.Enum,
      values: [
        :library,
        :museum,
        :gallery,
        :archive,
        :school,
        :publisher,
        :community,
        :government,
        :other
      ]

    field :institution_size, Ecto.Enum, values: [:small, :medium, :large, :enterprise]

    field :avatar_url, :string
    field :cover_url, :string

    field :website, :string
    field :email, :string
    field :phone, :string
    field :whatsapp, :string
    field :address, :string
    field :city, :string
    field :province, :string

    field :social_links, :map, default: %{}

    field :is_public, :boolean, default: true
    field :is_verified, :boolean, default: false
    field :verified_at, :utc_datetime
    field :follower_count, :integer, default: 0
    field :post_count, :integer, default: 0
    field :event_count, :integer, default: 0

    field :deleted_at, :utc_datetime

    timestamps()
  end
end
