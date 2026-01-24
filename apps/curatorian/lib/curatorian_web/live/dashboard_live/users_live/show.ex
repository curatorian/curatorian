defmodule CuratorianWeb.DashboardLive.UsersLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias Voile.Schema.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <.header>
        {@page_title}
        <:subtitle>
          User details and information
        </:subtitle>
        <:actions>
          <.link navigate={~p"/dashboard/admin/users"} class="btn-secondary">
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back to Users
          </.link>
          <.link navigate={~p"/dashboard/admin/users/#{@user.id}/edit"} class="btn-primary">
            <.icon name="hero-pencil" class="w-4 h-4 mr-2" /> Edit User
          </.link>
        </:actions>
      </.header>

      <div class="mt-6 bg-white dark:bg-gray-800 rounded-lg shadow-lg overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100">User Information</h2>
        </div>

        <div class="p-6">
          <div class="flex items-center space-x-6 mb-6">
            <img
              src={@user.user_image || "/images/default.png"}
              alt={@user.username}
              class="w-20 h-20 rounded-full object-cover"
            />
            <div>
              <h3 class="text-xl font-bold text-gray-900 dark:text-gray-100">
                {@user.fullname || @user.username}
              </h3>
              <p class="text-gray-600 dark:text-gray-400">@{@user.username}</p>
              <div class="mt-2">
                <%= if @user.confirmed_at do %>
                  <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                    Confirmed
                  </span>
                <% else %>
                  <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200">
                    Unconfirmed
                  </span>
                <% end %>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h4 class="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Basic Information
              </h4>
              <dl class="mt-2 space-y-2">
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Email</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">{@user.email}</dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Username</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">{@user.username}</dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Full Name</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">
                    {@user.fullname || "Not provided"}
                  </dd>
                </div>
              </dl>
            </div>

            <div>
              <h4 class="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Account Status
              </h4>
              <dl class="mt-2 space-y-2">
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Status</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">
                    <%= if @user.confirmed_at do %>
                      Confirmed on {Calendar.strftime(@user.confirmed_at, "%B %d, %Y")}
                    <% else %>
                      Unconfirmed
                    <% end %>
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Joined</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">
                    {Calendar.strftime(@user.inserted_at, "%B %d, %Y")}
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Last Login</dt>
                  <dd class="text-sm text-gray-900 dark:text-gray-100">
                    <%= if @user.last_login do %>
                      {Calendar.strftime(@user.last_login, "%B %d, %Y at %I:%M %p")}
                    <% else %>
                      Never
                    <% end %>
                  </dd>
                </div>
              </dl>
            </div>
          </div>

          <div class="mt-6">
            <h4 class="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Roles
            </h4>
            <div class="mt-2 flex flex-wrap gap-2">
              <%= for role_assignment <- @user.user_role_assignments do %>
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                  {role_assignment.role.name}
                </span>
              <% end %>
              <%= if Enum.empty?(@user.user_role_assignments) do %>
                <span class="text-sm text-gray-500 dark:text-gray-400">No roles assigned</span>
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
    user = Accounts.get_user(id)

    socket
    |> assign(:page_title, "User Details")
    |> assign(:user, user)
    |> then(&{:noreply, &1})
  end
end
