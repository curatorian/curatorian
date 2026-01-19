defmodule CuratorianWeb.DashboardLive.OrgsLive.Index do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Orgs
  alias Curatorian.Orgs.Organization

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-700 shadow rounded-lg p-6">
      <.header>
        <h1 class="text-2xl font-bold text-gray-800 dark:text-gray-100">Organizations</h1>

        <:actions>
          <.link patch={~p"/dashboard/orgs/new"} class="ml-3"><.button class="btn btn-primary">+
              New Organization</.button></.link>
        </:actions>
      </.header>

      <div class="mt-4 text-gray-500 text-sm">
        {length(@organizations)} organization{if length(@organizations) != 1, do: "s"} found
      </div>

      <.table id="organizations" rows={@organizations}>
        <:col :let={org} label="Name">{org.name}</:col>

        <:col :let={org} label="Slug">
          <code class="bg-gray-100 dark:text-gray-600 px-2 py-1 rounded">{org.slug}</code>
        </:col>

        <:col :let={org} label="Description">{org.description}</:col>

        <:action :let={org}>
          <div class="flex justify-end space-x-3">
            <.link
              navigate={~p"/dashboard/orgs/#{org.slug}"}
              class="btn-primary text-indigo-600 hover:text-indigo-900 font-medium no-underline"
            >
              Show
            </.link>
            <.link
              patch={~p"/dashboard/orgs/#{org.slug}/edit"}
              class="btn-default text-indigo-600 hover:text-indigo-900 font-medium no-underline"
            >
              Edit
            </.link>
            <%= if @current_user.role && @current_user.role.slug == "super_admin" && org.status != "approved" do %>
              <.link
                phx-click={JS.push("approve", value: %{id: org.id})}
                class="btn-primary text-green-600 hover:text-green-900 font-medium no-underline"
              >
                Approve
              </.link>
            <% end %>
            <.link
              phx-click={JS.push("delete", value: %{id: org.id}) |> hide("##{org.id}")}
              data-confirm="Are you sure?"
              class="btn-cancel text-red-600 hover:text-red-900 font-medium no-underline"
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
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    current_user = Curatorian.Repo.preload(current_user, :role)
    organizations = Orgs.list_organizations(current_user)

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

    dbg(Orgs.get_user_role(organization, socket.assigns.current_scope.user))

    if Orgs.has_permission?(organization, socket.assigns.current_scope.user, :manage_all) do
      {:ok, _} = Orgs.delete_organization(organization)
      organizations = Orgs.list_organizations(socket.assigns.current_user)

      {:noreply,
       socket
       |> assign(:organizations, organizations)
       |> put_flash(:info, "Organization deleted")}
    else
      {:noreply,
       put_flash(socket, :error, "You don't have permission to delete this organization")}
    end
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    organization = Orgs.get_organization!(id)

    if socket.assigns.current_user.role && socket.assigns.current_user.role.slug == "super_admin" do
      {:ok, _} = Orgs.update_organization(organization, %{status: "approved"})
      organizations = Orgs.list_organizations(socket.assigns.current_user)

      {:noreply,
       socket
       |> assign(:organizations, organizations)
       |> put_flash(:info, "Organization approved")}
    else
      {:noreply,
       put_flash(socket, :error, "You don't have permission to approve this organization")}
    end
  end
end
