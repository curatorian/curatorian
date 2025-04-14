defmodule CuratorianWeb.DashboardLive.UserManagerLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <.header>
      User Profile
    </.header>
    """
  end

  def mount(params, _session, socket) do
    dbg(params)

    {:ok, socket}
  end
end
