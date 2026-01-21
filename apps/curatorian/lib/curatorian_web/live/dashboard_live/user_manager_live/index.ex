defmodule CuratorianWeb.DashboardLive.UserManagerLive.Index do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Accounts
  alias Curatorian.Authorization

  def render(assigns) do
    ~H"""
    <.header>
      User Management
      <:subtitle>Manage users, roles, and permissions</:subtitle>

      <:actions>
        <%= if @selected_users != [] do %>
          <.button phx-click="show_bulk_actions" class="mr-2">
            <.icon name="hero-users" class="w-4 h-4 mr-2" /> Bulk Actions ({length(@selected_users)})
          </.button>
        <% end %>
      </:actions>
    </.header>
    <%!-- Search & Filters --%>
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-4 mb-6">
      <form phx-change="search" phx-submit="search">
        <div class="grid grid-cols-1 items-center justify-center md:grid-cols-4 gap-4">
          <div>
            <.input
              type="text"
              name="search"
              value={@search}
              placeholder="Search by name, email, or username..."
              phx-debounce="300"
            />
          </div>

          <div class="fieldset mb-2">
            <select
              name="role_filter"
              phx-change="filter_role"
              class="w-full select"
            >
              <option value="">All Roles</option>

              <%= for role <- @available_roles do %>
                <option value={role.slug} selected={@role_filter == role.slug}>{role.name}</option>
              <% end %>
            </select>
          </div>

          <div class="fieldset mb-2">
            <select
              name="status_filter"
              phx-change="filter_status"
              class="w-full select"
            >
              <option value="">All Status</option>

              <option value="active" selected={@status_filter == "active"}>Active</option>

              <option value="inactive" selected={@status_filter == "inactive"}>Inactive</option>

              <option value="verified" selected={@status_filter == "verified"}>Verified</option>
            </select>
          </div>
        </div>

        <%= if @search != "" or @role_filter != "" or @status_filter != "" do %>
          <div class="mt-4">
            <.button type="button" phx-click="clear_filters" class="btn-secondary">
              <.icon name="hero-x-mark" class="w-4 h-4 mr-2" /> Clear Filters
            </.button>
          </div>
        <% end %>
      </form>
    </div>
    <%!-- User Table --%>
    <%= if @curatorians != [] do %>
      <div class="overflow-x-auto rounded-xl shadow">
        <table class="min-w-full divide-y divide-gray-200 bg-white dark:bg-gray-800 dark:divide-gray-700">
          <thead class="bg-gray-50 dark:bg-gray-900">
            <tr>
              <th class="px-6 py-3 text-left">
                <input
                  type="checkbox"
                  phx-click="toggle_all"
                  checked={length(@selected_users) == length(@curatorians) and @curatorians != []}
                  class="rounded border-gray-300 dark:border-gray-600 dark:bg-gray-700"
                />
              </th>

              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                User
              </th>

              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Email
              </th>

              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Role
              </th>

              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Status
              </th>

              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Last Login
              </th>

              <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>

          <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
            <%= for user <- @curatorians do %>
              <tr class="hover:bg-gray-50 dark:hover:bg-gray-700">
                <td class="px-6 py-4">
                  <input
                    type="checkbox"
                    phx-click="toggle_user"
                    phx-value-user-id={user.id}
                    checked={user.id in @selected_users}
                    class="rounded border-gray-300 dark:border-gray-600 dark:bg-gray-700"
                  />
                </td>

                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center gap-3">
                    <%= if user.profile.user_image do %>
                      <img
                        src={user.profile.user_image}
                        referrerPolicy="no-referrer"
                        class="w-10 h-10 rounded-full"
                      />
                    <% else %>
                      <div class="w-10 h-10 rounded-full bg-gray-300 dark:bg-gray-600 flex items-center justify-center">
                        <span class="text-gray-700 dark:text-gray-200 font-semibold">
                          {String.first(user.profile.fullname || "?")}
                        </span>
                      </div>
                    <% end %>

                    <div>
                      <div class="text-sm font-medium text-gray-900 dark:text-gray-100">
                        {user.profile.fullname}
                      </div>

                      <div class="text-sm text-gray-500 dark:text-gray-400">@{user.username}</div>
                    </div>
                  </div>
                </td>

                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                  {user.email}
                </td>

                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={[
                    "px-2 py-1 text-xs font-semibold rounded-full",
                    get_role_badge_class(user)
                  ]}>
                    {get_role_name(user)}
                  </span>
                </td>

                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center gap-2">
                    <%= if is_user_active?(user) do %>
                      <span class="flex items-center gap-1 text-xs text-green-600 dark:text-green-400">
                        <span class="w-2 h-2 bg-green-500 rounded-full"></span> Active
                      </span>
                    <% else %>
                      <span class="flex items-center gap-1 text-xs text-gray-400">
                        <span class="w-2 h-2 bg-gray-400 rounded-full"></span> Inactive
                      </span>
                    <% end %>

                    <%= if user.is_verified do %>
                      <.icon name="hero-check-badge" class="w-4 h-4 text-blue-500" />
                    <% end %>
                  </div>
                </td>

                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                  <%= if user.last_login do %>
                    {format_last_login(user.last_login)}
                  <% else %>
                    Never
                  <% end %>
                </td>

                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <div class="flex items-center justify-end gap-2">
                    <.link
                      navigate={~p"/dashboard/user_manager/#{user.username}"}
                      class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300"
                    >
                      <.icon name="hero-eye" class="w-5 h-5" />
                    </.link>
                    <.link
                      navigate={~p"/dashboard/user_manager/#{user.username}/edit"}
                      class="text-green-600 hover:text-green-900 dark:text-green-400 dark:hover:text-green-300"
                    >
                      <.icon name="hero-pencil-square" class="w-5 h-5" />
                    </.link>
                    <%= if @can_delete do %>
                      <button
                        phx-click="confirm_delete"
                        phx-value-user-id={user.id}
                        phx-value-username={user.username}
                        class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300"
                      >
                        <.icon name="hero-trash" class="w-5 h-5" />
                      </button>
                    <% end %>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
      <%!-- Pagination --%>
      <div class="flex items-center justify-between mt-6">
        <div class="text-sm text-gray-700 dark:text-gray-300">
          Showing <span class="font-medium">{length(@curatorians)}</span>
          of <span class="font-medium">{@total_users}</span>
          users
        </div>

        <div class="flex items-center gap-2">
          <%= if @page > 1 do %>
            <.link
              patch={build_query_string(@page - 1, @search, @role_filter, @status_filter)}
              class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
            >
              Previous
            </.link>
          <% else %>
            <span class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm font-medium text-gray-400 bg-gray-100 dark:bg-gray-700 cursor-not-allowed">
              Previous
            </span>
          <% end %>

          <span class="text-sm text-gray-700 dark:text-gray-300">Page {@page} of {@total_pages}</span>
          <%= if @page < @total_pages do %>
            <.link
              patch={build_query_string(@page + 1, @search, @role_filter, @status_filter)}
              class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
            >
              Next
            </.link>
          <% else %>
            <span class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm font-medium text-gray-400 bg-gray-100 dark:bg-gray-700 cursor-not-allowed">
              Next
            </span>
          <% end %>
        </div>
      </div>
    <% else %>
      <div class="text-center py-12 bg-white dark:bg-gray-800 rounded-lg shadow">
        <.icon name="hero-users" class="w-12 h-12 mx-auto text-gray-400 mb-4" />
        <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">No users found</h3>

        <p class="text-gray-500 dark:text-gray-400">Try adjusting your search or filters</p>
      </div>
    <% end %>
    <%!-- Delete Confirmation Modal --%>
    <%= if @show_delete_modal do %>
      <.modal id="delete-modal" show on_cancel={JS.push("cancel_delete")}>
        <div class="text-center">
          <.icon name="hero-exclamation-triangle" class="w-12 h-12 mx-auto text-red-600 mb-4" />
          <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">Delete User</h3>

          <p class="text-sm text-gray-500 dark:text-gray-400 mb-6">
            Are you sure you want to delete <strong>{@delete_username}</strong>?
            This action cannot be undone.
          </p>

          <div class="flex items-center justify-center gap-4">
            <.button type="button" phx-click="cancel_delete" class="btn-secondary">Cancel</.button>
            <.button
              type="button"
              phx-click="delete_user"
              phx-value-user-id={@delete_user_id}
              class="bg-red-600 hover:bg-red-700"
            >
              Delete User
            </.button>
          </div>
        </div>
      </.modal>
    <% end %>
    <%!-- Bulk Actions Modal --%>
    <%= if @show_bulk_modal do %>
      <.modal id="bulk-modal" show on_cancel={JS.push("cancel_bulk")}>
        <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-4">
          Bulk Actions ({length(@selected_users)} users selected)
        </h3>

        <div class="space-y-4">
          <div class="fieldset mb-2">
            <label>
              <span class="label mb-1">Assign Role</span>
              <select
                name="bulk_role"
                phx-change="set_bulk_role"
                class="w-full select"
              >
                <option value="">Select a role...</option>

                <%= for role <- @available_roles do %>
                  <option value={role.id}>{role.name}</option>
                <% end %>
              </select>
            </label>
          </div>

          <div class="flex items-center justify-end gap-4 pt-4">
            <.button type="button" phx-click="cancel_bulk" class="btn-secondary">Cancel</.button>
            <.button type="button" phx-click="apply_bulk_role" phx-disable-with="Applying...">
              Apply to Selected Users
            </.button>
          </div>
        </div>
      </.modal>
    <% end %>
    """
  end

  def mount(params, _session, socket) do
    current_user = socket.assigns.current_scope.user

    # Get available roles
    available_roles = Authorization.list_roles()

    # Check permissions
    can_delete = Authorization.is_super_admin?(current_user)

    socket =
      socket
      |> assign(:search, params["search"] || "")
      |> assign(:role_filter, params["role_filter"] || "")
      |> assign(:status_filter, params["status_filter"] || "")
      |> assign(:page, String.to_integer(params["page"] || "1"))
      |> assign(:available_roles, available_roles)
      |> assign(:can_delete, can_delete)
      |> assign(:selected_users, [])
      |> assign(:show_delete_modal, false)
      |> assign(:delete_user_id, nil)
      |> assign(:delete_username, nil)
      |> assign(:show_bulk_modal, false)
      |> assign(:bulk_role_id, nil)
      |> assign(:page_title, "User Management")
      |> load_users()

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:search, params["search"] || "")
      |> assign(:role_filter, params["role_filter"] || "")
      |> assign(:status_filter, params["status_filter"] || "")
      |> assign(:page, String.to_integer(params["page"] || "1"))
      |> load_users()

    {:noreply, socket}
  end

  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     push_patch(socket,
       to: build_query_string(1, search, socket.assigns.role_filter, socket.assigns.status_filter)
     )}
  end

  def handle_event("filter_role", %{"role_filter" => role_filter}, socket) do
    {:noreply,
     push_patch(socket,
       to: build_query_string(1, socket.assigns.search, role_filter, socket.assigns.status_filter)
     )}
  end

  def handle_event("filter_status", %{"status_filter" => status_filter}, socket) do
    {:noreply,
     push_patch(socket,
       to: build_query_string(1, socket.assigns.search, socket.assigns.role_filter, status_filter)
     )}
  end

  def handle_event("clear_filters", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/dashboard/user_manager")}
  end

  def handle_event("toggle_user", %{"user-id" => user_id}, socket) do
    selected_users =
      if user_id in socket.assigns.selected_users do
        List.delete(socket.assigns.selected_users, user_id)
      else
        [user_id | socket.assigns.selected_users]
      end

    {:noreply, assign(socket, :selected_users, selected_users)}
  end

  def handle_event("toggle_all", _, socket) do
    selected_users =
      if length(socket.assigns.selected_users) == length(socket.assigns.curatorians) do
        []
      else
        Enum.map(socket.assigns.curatorians, & &1.id)
      end

    {:noreply, assign(socket, :selected_users, selected_users)}
  end

  def handle_event("confirm_delete", %{"user-id" => user_id, "username" => username}, socket) do
    {:noreply,
     socket
     |> assign(:show_delete_modal, true)
     |> assign(:delete_user_id, user_id)
     |> assign(:delete_username, username)}
  end

  def handle_event("cancel_delete", _, socket) do
    {:noreply,
     socket
     |> assign(:show_delete_modal, false)
     |> assign(:delete_user_id, nil)
     |> assign(:delete_username, nil)}
  end

  def handle_event("delete_user", %{"user-id" => user_id}, socket) do
    case Accounts.delete_user(user_id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "User deleted successfully")
         |> assign(:show_delete_modal, false)
         |> assign(:delete_user_id, nil)
         |> assign(:delete_username, nil)
         |> load_users()}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete user")
         |> assign(:show_delete_modal, false)}
    end
  end

  def handle_event("show_bulk_actions", _, socket) do
    {:noreply, assign(socket, :show_bulk_modal, true)}
  end

  def handle_event("cancel_bulk", _, socket) do
    {:noreply,
     socket
     |> assign(:show_bulk_modal, false)
     |> assign(:bulk_role_id, nil)}
  end

  def handle_event("set_bulk_role", %{"bulk_role" => role_id}, socket) do
    {:noreply, assign(socket, :bulk_role_id, role_id)}
  end

  def handle_event("apply_bulk_role", _, socket) do
    role_id = socket.assigns.bulk_role_id
    user_ids = socket.assigns.selected_users

    if role_id && role_id != "" do
      case Accounts.bulk_update_user_roles(user_ids, role_id) do
        {:ok, count} ->
          {:noreply,
           socket
           |> put_flash(:info, "Updated #{count} users successfully")
           |> assign(:show_bulk_modal, false)
           |> assign(:selected_users, [])
           |> assign(:bulk_role_id, nil)
           |> load_users()}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to update users")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please select a role")}
    end
  end

  # Helper functions

  defp load_users(socket) do
    params = %{
      "page" => socket.assigns.page,
      "search" => socket.assigns.search,
      "role_filter" => socket.assigns.role_filter,
      "status_filter" => socket.assigns.status_filter
    }

    result = Accounts.list_all_curatorian(params)

    socket
    |> assign(:curatorians, result.curatorians)
    |> assign(:total_pages, result.total_pages)
    |> assign(:total_users, result.total_users)
  end

  defp build_query_string(page, search, role_filter, status_filter) do
    query =
      []
      |> maybe_add_param("page", page, page != 1)
      |> maybe_add_param("search", search, search != "")
      |> maybe_add_param("role_filter", role_filter, role_filter != "")
      |> maybe_add_param("status_filter", status_filter, status_filter != "")
      |> Enum.join("&")

    if query == "" do
      ~p"/dashboard/user_manager"
    else
      ~p"/dashboard/user_manager?#{query}"
    end
  end

  defp maybe_add_param(list, _key, _value, false), do: list

  defp maybe_add_param(list, key, value, true),
    do: list ++ ["#{key}=#{URI.encode_www_form(to_string(value))}"]

  defp get_role_name(user) do
    if user.role do
      user.role.name
    else
      String.capitalize(user.user_role || "User")
    end
  end

  defp get_role_badge_class(user) do
    role_slug = if user.role, do: user.role.slug, else: user.user_role

    case role_slug do
      "super_admin" -> "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
      "manager" -> "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
      "curator" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200"
    end
  end

  defp is_user_active?(user) do
    if user.last_login do
      # Active if logged in within last 30 days
      days_since_login = DateTime.diff(DateTime.utc_now(), user.last_login, :day)
      days_since_login <= 30
    else
      false
    end
  end

  defp format_last_login(nil), do: "Never"

  defp format_last_login(datetime) do
    days_ago = DateTime.diff(DateTime.utc_now(), datetime, :day)

    cond do
      days_ago == 0 -> "Today"
      days_ago == 1 -> "Yesterday"
      days_ago < 7 -> "#{days_ago} days ago"
      days_ago < 30 -> "#{div(days_ago, 7)} weeks ago"
      true -> "#{div(days_ago, 30)} months ago"
    end
  end
end
