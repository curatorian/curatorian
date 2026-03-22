defmodule Curatorian.Public.OrgPageFollower do
  @moduledoc "Read-only schema for atrium.org_page_followers."

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @schema_prefix "atrium"

  schema "org_page_followers" do
    field :org_page_id, :binary_id
    field :voile_user_id, Ecto.UUID

    timestamps(updated_at: false)
  end
end
