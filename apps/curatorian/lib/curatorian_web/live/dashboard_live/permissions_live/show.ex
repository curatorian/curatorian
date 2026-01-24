defmodule CuratorianWeb.DashboardLive.PermissionsLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias VoileWeb.Auth.PermissionManager

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <.header>
        {@page_title}
        <:subtitle>
          Permission details and assignments
        </:subtitle>
        <:actions>
          <.link navigate={~p"/dashboard/admin/permissions"} class="btn-secondary">
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back to Permissions
          </.link>
          <.link
            navigate={~p"/dashboard/admin/permissions/#{@permission.id}/edit"}
            class="btn-primary"
          >
            <.icon name="hero-pencil" class="w-4 h-4 mr-2" /> Edit Permission
          </.link>
        </:actions>
      </.header>

      <div class="mt-6 bg-white dark:bg-gray-800 rounded-lg shadow-lg overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
            Permission Information
          </h2>
        </div>

        <div class="p-6">
          <div class="mb-6">
            <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100">
              {@permission.name}
            </h3>
            <p class="text-gray-600 dark:text-gray-400 mt-1">{@permission.description}</p>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h4 class="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Basic Information
              </h4>
              <dl class="mt-2 space-y-2">
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Name</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">{@permission.name}</dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Resource</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">{@permission.resource}</dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Action</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">{@permission.action}</dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Description</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">
                    {@permission.description || "No description"}
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
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Roles</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">
                    {length(@permission.roles)} roles
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Direct Users</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">
                    {length(@permission.user_permissions)} users
                  </dd>
                </div>
              </dl>
            </div>
          </div>

          <div class="mt-6">
            <h4 class="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Assigned Roles
            </h4>
            <div class="mt-2">
              <%= if Enum.empty?(@permission.roles) do %>
                <p class="text-sm text-gray-500 dark:text-gray-400">No roles assigned</p>
              <% else %>
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
                  <%= for role <- @permission.roles do %>
                    <div class="flex items-center p-2 bg-gray-50 dark:bg-gray-700 rounded-md">
                      <div class="flex-1">
                        <div class="text-sm font-medium text-gray-900 dark:text-gray-100">
                          {role.name}
                        </div>
                        <div class="text-xs text-gray-500 dark:text-gray-400">
                          {role.description}
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
    permission = PermissionManager.get_permission(String.to_integer(id))

    socket
    |> assign(:page_title, "Permission Details")
    |> assign(:permission, permission)
    |> then(&{:noreply, &1})
  end
end
