defmodule CuratorianWeb.DashboardLive.UserManagerLive.Index do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <.header>
      User Management
    </.header>

    <section>
      <p>Hello, {@current_user.profile.fullname}!</p>
       <hr />
      <%= if @curatorians do %>
        <h6 class="mt-8">All User List</h6>
        
        <div class="overflow-x-auto rounded-xl shadow my-5">
          <table class="min-w-full divide-y divide-gray-200 bg-white">
            <thead>
              <tr>
                <td class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Username
                </td>
                
                <td class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </td>
                
                <td class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Email
                </td>
                
                <td class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Role
                </td>
                
                <td class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Action
                </td>
              </tr>
            </thead>
            
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for user <- @curatorians do %>
                <tr class="hover:bg-gray-100">
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 flex items-center gap-2">
                    <img
                      src={user.profile.user_image}
                      referrerPolicy="no-referrer"
                      class="w-8 h-8 rounded"
                    />
                    <span>
                      {user.username}
                    </span>
                  </td>
                  
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    {user.profile.fullname}
                  </td>
                  
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {user.email}
                  </td>
                  
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {user.user_role}
                  </td>
                  
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <.link
                      patch={~p"/dashboard/user_manager/#{user.username}/edit"}
                      class="text-blue-600 hover:text-blue-900"
                    >
                      Edit
                    </.link>
                    
                    <.link
                      patch={~p"/dashboard/user_manager/#{user.username}/delete"}
                      class="text-red-600 hover:text-red-900"
                    >
                      Delete
                    </.link>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% else %>
        <p>No users found.</p>
      <% end %>
    </section>
    """
  end

  def mount(params, _session, socket) do
    all_users = Accounts.list_all_curatorian(params)

    socket =
      socket
      |> assign(:curatorians, all_users.curatorians)
      |> assign(:page, all_users.page)
      |> assign(:total_pages, all_users.total_pages)
      |> assign(:page_title, "User Management")

    {:ok, socket}
  end
end
