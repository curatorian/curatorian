defmodule CuratorianWeb.DashboardLive.OrgsLive.Index do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Orgs
  alias Curatorian.Orgs.Organization

  @impl true
  def render(assigns) do
    ~H"""
    <h4>Organization</h4>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    current_user = socket.assigns.current_user || session["current_user"]
    organizations = Orgs.list_organizations()

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:organizations, organizations)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Organizations")
    |> assign(:organization, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Organization")
    |> assign(:organization, %Organization{})
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    organization = Orgs.get_organization!(id)

    if Orgs.has_permission?(organization, socket.assigns.current_user, :manage_all) do
      {:ok, _} = Orgs.delete_organization(organization)
      organizations = Orgs.list_organizations()

      {:noreply,
       socket
       |> assign(:organizations, organizations)
       |> put_flash(:info, "Organization deleted")}
    else
      {:noreply,
       put_flash(socket, :error, "You don't have permission to delete this organization")}
    end
  end
end
