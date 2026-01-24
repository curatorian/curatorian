defmodule CuratorianWeb.DashboardLive.RolesLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias VoileWeb.Auth.PermissionManager

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <.header>
        {@page_title}
        <:subtitle>
          Role details and permissions
        </:subtitle>
        <:actions>
          <.link navigate={~p"/dashboard/admin/roles"} class="btn-secondary">
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back to Roles
          </.link>
          <%= unless @role.is_system_role do %>
            <.link navigate={~p"/dashboard/admin/roles/#{@role.id}/edit"} class="btn-primary">
              <.icon name="hero-pencil" class="w-4 h-4 mr-2" /> Edit Role
            </.link>
          <% end %>
        </:actions>
      </.header>

      <div class="mt-6 bg-white dark:bg-gray-800 rounded-lg shadow-lg overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Role Information</h2>
        </div>

        <div class="p-6">
          <div class="mb-6">
            <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100">
              {@role.name}
            </h3>
            <p class="text-gray-600 dark:text-gray-400 mt-1">{@role.description}</p>
            <div class="mt-2">
              <%= if @role.is_system_role do %>
                <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200">
                  System Role
                </span>
              <% else %>
                <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                  Custom Role
                </span>
              <% end %>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h4 class="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Basic Information
              </h4>
              <dl class="mt-2 space-y-2">
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Name</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">{@role.name}</dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Description</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">
                    {@role.description || "No description"}
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">System Role</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">
                    {if @role.is_system_role, do: "Yes", else: "No"}
                  </dd>
                </div>
              </dl>
            </div>

            <div>
              <h4 class="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Statistics
              </h4>
              <dl class="mt-2 space-y-2">
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Permissions</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">
                    {length(@role.permissions)} permissions
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Users</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">
                    {length(PermissionManager.list_users_with_role(@role.id))} users
                  </dd>
                </div>
              </dl>
            </div>
          </div>

          <div class="mt-6">
            <h4 class="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Permissions
            </h4>
            <div class="mt-2">
              <%= if Enum.empty?(@role.permissions) do %>
                <p class="text-sm text-gray-500 dark:text-gray-400">No permissions assigned</p>
              <% else %>
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
                  <%= for permission <- @role.permissions do %>
                    <div class="flex items-center p-2 bg-gray-50 dark:bg-gray-700 rounded-md">
                      <div class="flex-1">
                        <div class="text-sm font-medium text-gray-900 dark:text-gray-100">
                          {permission.name}
                        </div>
                        <div class="text-xs text-gray-500 dark:text-gray-400">
                          {permission.resource}. {permission.action}
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    role = PermissionManager.get_role(String.to_integer(id))

    socket
    |> assign(:page_title, "Role Details")
    |> assign(:role, role)
    |> then(&{:noreply, &1})
  end
end
