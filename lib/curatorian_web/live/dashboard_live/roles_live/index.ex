defmodule CuratorianWeb.DashboardLive.RolesLive.Index do
  use CuratorianWeb, :live_view

  alias Curatorian.Authorization

  @impl true
  def mount(_params, _session, socket) do
    roles = Authorization.list_roles()

    socket =
      socket
      |> assign(:page_title, "Role Management")
      |> assign(:roles, roles)

    {:ok, socket}
  end

  @impl true
  def handle_event("delete_role", %{"id" => id}, socket) do
    role = Authorization.get_role!(id)

    case Authorization.delete_role(role) do
      {:ok, _role} ->
        socket =
          socket
          |> put_flash(:info, "Role deleted successfully")
          |> assign(:roles, Authorization.list_roles())

        {:noreply, socket}

      {:error, _reason} ->
        socket = put_flash(socket, :error, "Cannot delete this role")
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="sm:flex sm:items-center sm:justify-between mb-6">
          <div>
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Role Management</h1>
            
            <p class="mt-2 text-sm text-gray-700 dark:text-gray-300">
              Manage user roles and their permissions
            </p>
          </div>
          
          <div class="mt-4 sm:mt-0">
            <.link
              navigate={~p"/dashboard/admin/roles/new"}
              class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-violet-600 hover:bg-violet-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-violet-500"
            >
              <.icon name="hero-plus" class="h-5 w-5 mr-2" /> New Role
            </.link>
          </div>
        </div>
        
        <div class="bg-white dark:bg-gray-800 shadow overflow-hidden sm:rounded-lg">
          <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead class="bg-gray-50 dark:bg-gray-900">
              <tr>
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                >
                  Role Name
                </th>
                
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                >
                  Slug
                </th>
                
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                >
                  Description
                </th>
                
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                >
                  Priority
                </th>
                
                <th
                  scope="col"
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                >
                  Permissions
                </th>
                
                <th scope="col" class="relative px-6 py-3"><span class="sr-only">Actions</span></th>
              </tr>
            </thead>
            
            <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
              <tr :for={role <- @roles} class="hover:bg-gray-50 dark:hover:bg-gray-700">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <div class="text-sm font-medium text-gray-900 dark:text-white">
                      {role.name}
                      <%= if role.is_system_role do %>
                        <span class="ml-2 inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                          System
                        </span>
                      <% end %>
                    </div>
                  </div>
                </td>
                
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-900 dark:text-gray-300">{role.slug}</div>
                </td>
                
                <td class="px-6 py-4">
                  <div class="text-sm text-gray-500 dark:text-gray-400">
                    {role.description || "-"}
                  </div>
                </td>
                
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-900 dark:text-gray-300">{role.priority}</div>
                </td>
                
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-900 dark:text-gray-300">
                    {length(role.permissions)} permissions
                  </div>
                </td>
                
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <.link
                    navigate={~p"/dashboard/admin/roles/#{role.id}/edit"}
                    class="text-violet-600 hover:text-violet-900 dark:text-violet-400 dark:hover:text-violet-300 mr-4"
                  >
                    Edit
                  </.link>
                  <%= if not role.is_system_role do %>
                    <button
                      phx-click="delete_role"
                      phx-value-id={role.id}
                      data-confirm="Are you sure you want to delete this role?"
                      class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300"
                    >
                      Delete
                    </button>
                  <% end %>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
