defmodule CuratorianWeb.DashboardLive.OrgsLive.Index do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Orgs

  def render(assigns) do
    ~H"""
    <h4>Organization</h4>
    """
  end

  def mount(_params, _session, socket) do
    orgs = Orgs.list_organizations()

    socket =
      socket
      |> assign(:orgs, orgs)

    {:ok, socket}
  end
end
