defmodule Curatorian.Public.CrowdfundingCampaign do
  @moduledoc "Read-only schema for atrium.crowdfunding_campaigns."
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "crowdfunding_campaigns" do
    field :host_org_page_id, :binary_id
    field :host_user_id, Ecto.UUID

    field :title, :string
    field :slug, :string
    field :description, :string
    field :cover_image_url, :string

    field :campaign_type, Ecto.Enum, values: [:money, :collection_items, :mixed]

    field :category, Ecto.Enum,
      values: [:library, :archives, :museum, :gallery, :education, :research, :other]

    field :goal_amount_idr, :integer
    field :raised_amount_idr, :integer
    field :platform_fee_percent, :integer

    field :item_goal_description, :string
    field :item_goal_count, :integer
    field :item_received_count, :integer

    field :is_permanent, :boolean
    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime

    field :status, Ecto.Enum, values: [:draft, :active, :goal_reached, :completed, :canceled]

    field :donor_count, :integer
    field :item_pledge_count, :integer
    field :deleted_at, :utc_datetime

    timestamps()
  end
end
