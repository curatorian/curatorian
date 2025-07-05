defmodule CuratorianWeb.DashboardLive.OrgsLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Orgs

  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 min-h-screen">
      <!-- Cover Image -->
      <div class="h-64 bg-gray-300 relative">
        <img
          src={@organization.image_cover || "/images/default-cover.jpg"}
          class="w-full h-full object-cover"
        />
        
    <!-- Profile Image -->
        <div class="absolute bottom-0 left-8 transform translate-y-1/2">
          <img
            src={@organization.image_logo || "/images/default-avatar.jpg"}
            class="w-32 h-32 rounded-full border-4 border-white bg-white"
          />
        </div>
      </div>
      
    <!-- Organization Info -->
      <div class="mt-16 px-8">
        <h1 class="text-3xl font-bold">{@organization.name}</h1>
        
        <p class="text-gray-600">{@organization.description}</p>
        
    <!-- Action Buttons -->
        <div class="mt-4 flex space-x-2">
          <%= if @current_user do %>
            <%= if is_member?(@organization, @current_user) do %>
              <button phx-click="leave" class="px-4 py-2 bg-red-600 text-white rounded">
                Leave
              </button>
            <% else %>
              <button phx-click="join" class="px-4 py-2 bg-blue-600 text-white rounded">
                Join
              </button>
            <% end %>
          <% end %>
          
          <%= if Orgs.has_permission?(@organization, @current_user, :manage_all) do %>
            <.link
              patch={~p"/dashboard/orgs/#{@organization.slug}/edit"}
              class="px-4 py-2 bg-gray-600 text-white rounded"
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
            <div class="bg-white p-6 rounded-lg shadow">
              <h3 class="text-xl font-semibold mb-4">About</h3>
              
              <p class="text-gray-700">{@organization.description}</p>
              
              <div class="mt-6">
                <h4 class="font-semibold mb-2">Organization Details</h4>
                
                <ul class="space-y-2">
                  <li class="flex">
                    <span class="w-32 text-gray-500">Status:</span>
                    <span>{@organization.status}</span>
                  </li>
                  
                  <li class="flex">
                    <span class="w-32 text-gray-500">Type:</span> <span>{@organization.type}</span>
                  </li>
                  
                  <li class="flex">
                    <span class="w-32 text-gray-500">Created:</span>
                    <span>{@organization.inserted_at}</span>
                  </li>
                </ul>
              </div>
            </div>
          <% :members -> %>
            <div class="bg-white p-6 rounded-lg shadow">
              <h3 class="text-xl font-semibold mb-4">Members</h3>
              
              <table class="min-w-full">
                <thead>
                  <tr class="border-b">
                    <th class="text-left py-2">Name</th>
                    
                    <th class="text-left py-2">Role</th>
                    
                    <th class="text-left py-2">Joined</th>
                  </tr>
                </thead>
                
                <tbody>
                  <%= for ou <- @organization.organization_users do %>
                    <tr class="border-b hover:bg-gray-50">
                      <td class="py-3">
                        <div class="flex items-center">
                          <img
                            src={ou.user.avatar_url || "/images/default-avatar.jpg"}
                            class="w-10 h-10 rounded-full mr-3"
                          /> <span>{ou.user.name}</span>
                        </div>
                      </td>
                      
                      <td class="py-3">{ou.organization_role.label}</td>
                      
                      <td class="py-3">{ou.joined_at}</td>
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
    current_user = socket.assigns.current_user || session["current_user"]
    organization = Orgs.get_organization_by_slug(slug)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:organization, organization)
     |> assign(:active_tab, :about)
     |> allow_upload(:profile_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)
     |> allow_upload(:cover_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  defp is_member?(org, user), do: Orgs.get_user_role(org, user) != :guest
end
