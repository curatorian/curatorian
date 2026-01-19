defmodule CuratorianWeb.DashboardLive.OrgsLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Repo
  alias Curatorian.Orgs

  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 dark:bg-gray-900 h-full mb-16">
      <!-- Cover Image -->
      <div class="h-64 bg-gray-300 dark:bg-gray-700 relative">
        <img
          src={@organization.image_cover || "/images/default-cover.jpg"}
          class="w-full h-full object-cover"
        />
        <!-- Profile Image -->
        <div class="absolute bottom-0 left-8 transform translate-y-1/2">
          <img
            src={@organization.image_logo || "/images/default-avatar.jpg"}
            class="w-32 h-32 object-cover rounded-full border-4 border-white dark:border-gray-800 bg-white dark:bg-gray-800"
          />
        </div>
      </div>
      <!-- Organization Info -->
      <div class="mt-16 px-8">
        <h1 class="text-3xl font-bold text-gray-900 dark:text-white">{@organization.name}</h1>

        <p class="text-gray-700 dark:text-gray-300">{@organization.description}</p>
        <!-- Action Buttons -->
        <div class="mt-4 flex space-x-2">
          <%= if @current_user do %>
            <%= if is_owner?(@organization, @current_user) do %>
              <button
                phx-click="delete_org"
                data-confirm="Are you sure you want to delete this organization? This action cannot be undone."
                class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded"
              >
                Delete Organization
              </button>
            <% else %>
              <%= if is_member?(@organization, @current_user) do %>
                <button
                  phx-click="leave"
                  class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded"
                >
                  Leave
                </button>
              <% else %>
                <button
                  phx-click="join"
                  class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded"
                >
                  Join
                </button>
              <% end %>
            <% end %>
          <% end %>

          <%= if Orgs.has_permission?(@organization, @current_user, :manage_all) do %>
            <.link
              patch={~p"/dashboard/orgs/#{@organization.slug}/edit"}
              class="px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded no-underline"
            >
              Edit
            </.link>
          <% end %>
        </div>
      </div>
      <!-- Tab Content -->
      <div class="container mx-auto mt-4">
        <%= case @active_tab do %>
          <% :about -> %>
            <div class="bg-white dark:bg-gray-800 mx-5 p-6 rounded-lg shadow">
              <h3 class="text-xl font-semibold mb-4 text-gray-900 dark:text-white">About</h3>

              <p class="text-gray-700 dark:text-gray-300">{@organization.description}</p>

              <div class="mt-6">
                <h4 class="font-semibold mb-2 text-gray-900 dark:text-white">Organization Details</h4>

                <ul class="space-y-2">
                  <li class="flex">
                    <span class="w-32 text-gray-500 dark:text-gray-400">Status:</span>
                    <span class="text-gray-900 dark:text-white">{@organization.status}</span>
                  </li>

                  <li class="flex">
                    <span class="w-32 text-gray-500 dark:text-gray-400">Type:</span>
                    <span class="text-gray-900 dark:text-white">{@organization.type}</span>
                  </li>

                  <li class="flex">
                    <span class="w-32 text-gray-500 dark:text-gray-400">Created:</span>
                    <span class="text-gray-900 dark:text-white">{@organization.inserted_at}</span>
                  </li>
                </ul>
              </div>
            </div>
          <% :members -> %>
            <div class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow">
              <h3 class="text-xl font-semibold mb-4 text-gray-900 dark:text-white">Members</h3>

              <table class="min-w-full">
                <thead>
                  <tr class="border-b border-gray-200 dark:border-gray-600">
                    <th class="text-left py-2 text-gray-900 dark:text-white">Name</th>

                    <th class="text-left py-2 text-gray-900 dark:text-white">Role</th>

                    <th class="text-left py-2 text-gray-900 dark:text-white">Joined</th>
                  </tr>
                </thead>

                <tbody>
                  <%= for ou <- @organization.organization_users do %>
                    <tr class="border-b border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700">
                      <td class="py-3">
                        <div class="flex items-center">
                          <img
                            src={ou.user.avatar_url || "/images/default-avatar.jpg"}
                            class="w-10 h-10 rounded-full mr-3"
                          /> <span class="text-gray-900 dark:text-white">{ou.user.name}</span>
                        </div>
                      </td>

                      <td class="py-3 text-gray-900 dark:text-white">{ou.organization_role.label}</td>

                      <td class="py-3 text-gray-900 dark:text-white">{ou.joined_at}</td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(%{"slug" => slug}, session, socket) do
    current_user = socket.assigns.current_scope.user || session["current_user"]
    organization = Orgs.get_organization_by_slug(slug)

    current_user = if current_user, do: Repo.preload(current_user, :role), else: nil

    can_view? =
      organization.status == "approved" or
        (current_user &&
           (organization.owner_id == current_user.id or
              (current_user.role && current_user.role.slug == "super_admin")))

    if can_view? do
      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:organization, organization)
       |> assign(:active_tab, :about)
       |> allow_upload(:profile_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)
       |> allow_upload(:cover_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
    else
      {:ok,
       socket
       |> put_flash(:error, "Organization not found")
       |> push_navigate(to: ~p"/dashboard/orgs")}
    end
  end

  def handle_event("delete_org", _params, socket) do
    organization = socket.assigns.organization
    Orgs.delete_organization(organization)

    {:noreply, push_navigate(socket, to: ~p"/dashboard/orgs")}
  end

  defp is_member?(org, user), do: Orgs.get_user_role(org, user) != :guest
  defp is_owner?(org, user), do: Orgs.get_user_role(org, user) == "owner"
end
