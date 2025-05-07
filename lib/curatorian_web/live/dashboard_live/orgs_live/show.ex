defmodule CuratorianWeb.DashboardLive.OrgsLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Orgs
  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <.header>
      <div class="flex items-center justify-between">
        <div>
          Organization {@org.name}
        </div>
      </div>
    </.header>

    <.back navigate="/dashboard/orgs">Kembali</.back>

    <.list>
      <:item title="Name">{@org.name}</:item>
      
      <:item title="Slug">{@org.status}</:item>
      
      <:item title="Status">{@org.description}</:item>
      
      <:item title="Type">{@org.slug}</:item>
      
      <:item title="Description">{@org.type}</:item>
    </.list>
    """
  end

  def mount(%{"slug" => slug}, _session, socket) do
    org = Orgs.get_organization_by_slug(slug)
    user_profile = Accounts.get_user_profile_by_user_id(org.user_id)

    socket =
      socket
      |> assign(:org, org)
      |> assign(:user_profile, user_profile)

    {:ok, socket}
  end
end
