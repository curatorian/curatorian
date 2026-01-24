defmodule CuratorianWeb.DashboardLive.PermissionsLive.Index do
  use CuratorianWeb, :live_view_dashboard

  alias VoileWeb.Auth.PermissionManager

  @impl true
  def mount(_params, _session, socket) do
    permissions = PermissionManager.list_permissions()

    socket =
      socket
      |> assign(:permissions, permissions)
      |> assign(:page_title, "Permissions")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Permissions")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <.header>
        {@page_title}
        <:subtitle>
          Manage permissions and their assignments
        </:subtitle>
        <:actions>
          <.link navigate={~p"/dashboard/admin/permissions/new"} class="btn-primary">
            <.icon name="hero-plus" class="w-4 h-4 mr-2" /> New Permission
          </.link>
        </:actions>
      </.header>

      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Permissions</h2>
        </div>

        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead class="bg-gray-50 dark:bg-gray-700">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Permission
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Resource
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Action
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Description
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
              <%= for permission <- @permissions do %>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-700">
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm font-medium text-gray-900 dark:text-gray-100">
                      {permission.name}
                    </div>
                    <div class="text-sm text-gray-500 dark:text-gray-400">
                      {permission.name}
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                    {permission.resource}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                    {permission.action}
                  </td>
                  <td class="px-6 py-4 text-sm text-gray-900 dark:text-gray-100">
                    {permission.description}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <.link
                      navigate={~p"/dashboard/admin/permissions/#{permission.id}"}
                      class="text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300 mr-4"
                    >
                      View
                    </.link>
                    <.link
                      navigate={~p"/dashboard/admin/permissions/#{permission.id}/edit"}
                      class="text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300"
                    >
                      Edit
                    </.link>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>

        <%= if Enum.empty?(@permissions) do %>
          <div class="px-6 py-12 text-center">
            <svg
              class="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-gray-100">No permissions</h3>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
              Get started by creating a new permission.
            </p>
            <div class="mt-6">
              <.link navigate={~p"/dashboard/admin/permissions/new"} class="btn-primary">
                <.icon name="hero-plus" class="w-4 h-4 mr-2" /> New Permission
              </.link>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
