defmodule CuratorianWeb.DashboardLive.OrgsLive.Index do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Orgs
  alias Curatorian.Orgs.Organization

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg p-6">
      <.header class="mb-6">
        <h1 class="text-2xl font-bold text-gray-800">Organizations</h1>
        
        <:actions>
          <.link patch={~p"/dashboard/orgs/new"} class="ml-3">
            <.button class="bg-indigo-600 hover:bg-indigo-700">
              <span class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M10 3a1 1 0 00-1 1v5H4a1 1 0 100 2h5v5a1 1 0 102 0v-5h5a1 1 0 100-2h-5V4a1 1 0 00-1-1z"
                    clip-rule="evenodd"
                  />
                </svg>
                New Organization
              </span>
            </.button>
          </.link>
        </:actions>
      </.header>
      
      <div class="mt-4 text-gray-500 text-sm">
        {length(@organizations)} organization{if length(@organizations) != 1, do: "s"} found
      </div>
      
      <.table id="organizations" rows={@organizations}>
        <:col :let={org} label="Name">{org.name}</:col>
        
        <:col :let={org} label="Slug">
          <code class="bg-gray-100 px-2 py-1 rounded">{org.slug}</code>
        </:col>
        
        <:col :let={org} label="Description">{org.description}</:col>
        
        <:action :let={org}>
          <div class="flex justify-end space-x-3">
            <div class="sr-only">
              <.link navigate={~p"/dashboard/orgs/#{org.slug}"}>Show</.link>
            </div>
            
            <.link
              patch={~p"/dashboard/orgs/#{org.slug}/edit"}
              class="text-indigo-600 hover:text-indigo-900 font-medium"
            >
              Edit
            </.link>
            
            <.link
              phx-click={JS.push("delete", value: %{id: org.id}) |> hide("##{org.id}")}
              data-confirm="Are you sure?"
              class="text-red-600 hover:text-red-900 font-medium"
            >
              Delete
            </.link>
          </div>
        </:action>
      </.table>
    </div>
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

    dbg(Orgs.get_user_role(organization, socket.assigns.current_user))

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
