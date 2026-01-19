defmodule CuratorianWeb.DashboardLive.RolesLive.Form do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Authorization
  alias Curatorian.Authorization.Role

  @impl true
  def mount(params, _session, socket) do
    role_id = params["id"]

    {role, page_title} =
      if role_id do
        role = Authorization.get_role!(role_id)
        {role, "Edit Role"}
      else
        {%Role{}, "New Role"}
      end

    permissions = Authorization.list_permissions_by_resource()

    selected_permission_ids =
      if role.id, do: Enum.map(role.permissions, & &1.id), else: []

    form = to_form(Authorization.change_role(role))

    socket =
      socket
      |> assign(:page_title, page_title)
      |> assign(:role, role)
      |> assign(:form, form)
      |> assign(:permissions, permissions)
      |> assign(:selected_permission_ids, selected_permission_ids)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"role" => role_params}, socket) do
    changeset =
      socket.assigns.role
      |> Authorization.change_role(role_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"role" => role_params} = params, socket) do
    save_role(socket, socket.assigns.role, role_params, params)
  end

  @impl true
  def handle_event("toggle_permission", %{"permission-id" => permission_id}, socket) do
    selected = socket.assigns.selected_permission_ids

    selected_permission_ids =
      if permission_id in selected do
        List.delete(selected, permission_id)
      else
        [permission_id | selected]
      end

    {:noreply, assign(socket, :selected_permission_ids, selected_permission_ids)}
  end

  defp save_role(socket, %Role{id: nil}, role_params, params) do
    case Authorization.create_role(role_params) do
      {:ok, role} ->
        # Assign permissions
        permission_ids = get_permission_ids(params)
        Authorization.sync_role_permissions(role.id, permission_ids)

        socket =
          socket
          |> put_flash(:info, "Role created successfully")
          |> push_navigate(to: ~p"/dashboard/admin/roles")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_role(socket, %Role{} = role, role_params, params) do
    case Authorization.update_role(role, role_params) do
      {:ok, role} ->
        # Update permissions
        permission_ids = get_permission_ids(params)
        Authorization.sync_role_permissions(role.id, permission_ids)

        socket =
          socket
          |> put_flash(:info, "Role updated successfully")
          |> push_navigate(to: ~p"/dashboard/admin/roles")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp get_permission_ids(%{"permissions" => permissions}) when is_map(permissions) do
    permissions
    |> Map.values()
    |> Enum.filter(&(&1 == "true"))
    |> Enum.map(fn _ -> nil end)

    # Extract keys where value is "true"
    permissions
    |> Enum.filter(fn {_k, v} -> v == "true" end)
    |> Enum.map(fn {k, _v} -> k end)
  end

  defp get_permission_ids(_), do: []

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="mb-6">
        <.link
          navigate={~p"/dashboard/admin/roles"}
          class="text-sm text-violet-600 hover:text-violet-700 dark:text-violet-400"
        >
          ← Back to Roles
        </.link>
      </div>

      <div class="bg-white dark:bg-gray-800 shadow sm:rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">{@page_title}</h2>

          <.form for={@form} id="role-form" phx-change="validate" phx-submit="save">
            <div class="space-y-6">
              <div><.input field={@form[:name]} type="text" label="Role Name" required /></div>

              <div>
                <.input
                  field={@form[:slug]}
                  type="text"
                  label="Slug"
                  placeholder="e.g., content_manager"
                  required
                />
                <p class="mt-1 text-sm text-gray-500">
                  Use lowercase letters, numbers, and underscores only
                </p>
              </div>

              <div>
                <.input field={@form[:description]} type="textarea" label="Description" rows="3" />
              </div>

              <div>
                <.input
                  field={@form[:priority]}
                  type="number"
                  label="Priority"
                  value={@form[:priority].value || 0}
                />
                <p class="mt-1 text-sm text-gray-500">Higher priority roles appear first</p>
              </div>

              <%= if @role.is_system_role do %>
                <div class="rounded-md bg-blue-50 dark:bg-blue-900/20 p-4">
                  <div class="flex">
                    <div class="flex-shrink-0">
                      <.icon name="hero-information-circle" class="h-5 w-5 text-blue-400" />
                    </div>

                    <div class="ml-3">
                      <p class="text-sm text-blue-700 dark:text-blue-300">
                        This is a system role and some fields cannot be edited.
                      </p>
                    </div>
                  </div>
                </div>
              <% end %>

              <div>
                <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Permissions</h3>

                <div class="space-y-6">
                  <%= for {resource, perms} <- @permissions do %>
                    <div class="border dark:border-gray-700 rounded-lg p-4">
                      <h4 class="font-medium text-gray-900 dark:text-white mb-3 capitalize">
                        {resource}
                      </h4>

                      <div class="space-y-2">
                        <%= for permission <- perms do %>
                          <label class="flex items-center">
                            <input
                              type="checkbox"
                              name={"permissions[#{permission.id}]"}
                              value="true"
                              checked={permission.id in @selected_permission_ids}
                              phx-click="toggle_permission"
                              phx-value-permission-id={permission.id}
                              class="h-4 w-4 text-violet-600 focus:ring-violet-500 border-gray-300 rounded"
                            />
                            <span class="ml-3 text-sm text-gray-700 dark:text-gray-300">
                              {permission.name}
                              <%= if permission.description do %>
                                <span class="text-gray-500 dark:text-gray-400">
                                  - {permission.description}
                                </span>
                              <% end %>
                            </span>
                          </label>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>

              <div class="flex justify-end space-x-3">
                <.link
                  navigate={~p"/dashboard/admin/roles"}
                  class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-violet-500"
                >
                  Cancel
                </.link>
                <button
                  type="submit"
                  class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-violet-600 hover:bg-violet-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-violet-500"
                >
                  Save Role
                </button>
              </div>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
