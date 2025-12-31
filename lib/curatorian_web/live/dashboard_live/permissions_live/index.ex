defmodule CuratorianWeb.DashboardLive.PermissionsLive.Index do
  use CuratorianWeb, :live_view

  alias Curatorian.Authorization
  alias Curatorian.Authorization.Permission

  @impl true
  def mount(_params, _session, socket) do
    permissions_by_resource = Authorization.list_permissions_by_resource()

    socket =
      socket
      |> assign(:page_title, "Permission Management")
      |> assign(:permissions_by_resource, permissions_by_resource)
      |> assign(:show_form, false)
      |> assign(:form, to_form(Authorization.change_permission(%Permission{})))
      |> assign(:editing_permission, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("new_permission", _, socket) do
    form = to_form(Authorization.change_permission(%Permission{}))

    socket =
      socket
      |> assign(:show_form, true)
      |> assign(:form, form)
      |> assign(:editing_permission, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("edit_permission", %{"id" => id}, socket) do
    permission = Authorization.get_permission!(id)
    form = to_form(Authorization.change_permission(permission))

    socket =
      socket
      |> assign(:show_form, true)
      |> assign(:form, form)
      |> assign(:editing_permission, permission)

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_form", _, socket) do
    socket =
      socket
      |> assign(:show_form, false)
      |> assign(:editing_permission, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"permission" => permission_params}, socket) do
    permission = socket.assigns.editing_permission || %Permission{}

    changeset =
      permission
      |> Authorization.change_permission(permission_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"permission" => permission_params}, socket) do
    save_permission(socket, socket.assigns.editing_permission, permission_params)
  end

  @impl true
  def handle_event("delete_permission", %{"id" => id}, socket) do
    permission = Authorization.get_permission!(id)

    case Authorization.delete_permission(permission) do
      {:ok, _permission} ->
        socket =
          socket
          |> put_flash(:info, "Permission deleted successfully")
          |> assign(:permissions_by_resource, Authorization.list_permissions_by_resource())

        {:noreply, socket}

      {:error, _changeset} ->
        socket = put_flash(socket, :error, "Failed to delete permission")
        {:noreply, socket}
    end
  end

  defp save_permission(socket, nil, permission_params) do
    case Authorization.create_permission(permission_params) do
      {:ok, _permission} ->
        socket =
          socket
          |> put_flash(:info, "Permission created successfully")
          |> assign(:show_form, false)
          |> assign(:permissions_by_resource, Authorization.list_permissions_by_resource())

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_permission(socket, permission, permission_params) do
    case Authorization.update_permission(permission, permission_params) do
      {:ok, _permission} ->
        socket =
          socket
          |> put_flash(:info, "Permission updated successfully")
          |> assign(:show_form, false)
          |> assign(:editing_permission, nil)
          |> assign(:permissions_by_resource, Authorization.list_permissions_by_resource())

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="sm:flex sm:items-center sm:justify-between mb-6">
          <div>
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Permission Management</h1>
            
            <p class="mt-2 text-sm text-gray-700 dark:text-gray-300">
              Define granular permissions for different resources
            </p>
          </div>
          
          <div class="mt-4 sm:mt-0">
            <button
              phx-click="new_permission"
              class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-violet-600 hover:bg-violet-700"
            >
              <.icon name="hero-plus" class="h-5 w-5 mr-2" /> New Permission
            </button>
          </div>
        </div>
        
        <%= if @show_form do %>
          <div class="bg-white dark:bg-gray-800 shadow sm:rounded-lg p-6 mb-6">
            <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              {if @editing_permission, do: "Edit Permission", else: "New Permission"}
            </h2>
            
            <.form for={@form} id="permission-form" phx-change="validate" phx-submit="save">
              <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <.input field={@form[:name]} type="text" label="Permission Name" required />
                </div>
                
                <div><.input field={@form[:slug]} type="text" label="Slug" required /></div>
                
                <div><.input field={@form[:resource]} type="text" label="Resource" required /></div>
                
                <div>
                  <.input
                    field={@form[:action]}
                    type="select"
                    label="Action"
                    options={Permission.valid_actions()}
                    required
                  />
                </div>
                
                <div class="sm:col-span-2">
                  <.input field={@form[:description]} type="textarea" label="Description" rows="2" />
                </div>
              </div>
              
              <div class="mt-4 flex justify-end space-x-3">
                <button
                  type="button"
                  phx-click="cancel_form"
                  class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-violet-600 hover:bg-violet-700"
                >
                  Save
                </button>
              </div>
            </.form>
          </div>
        <% end %>
        
        <div class="space-y-6">
          <%= for {resource, permissions} <- @permissions_by_resource do %>
            <div class="bg-white dark:bg-gray-800 shadow overflow-hidden sm:rounded-lg">
              <div class="px-4 py-5 sm:px-6 bg-gray-50 dark:bg-gray-900">
                <h3 class="text-lg leading-6 font-medium text-gray-900 dark:text-white capitalize">
                  {resource}
                </h3>
              </div>
              
              <div class="border-t border-gray-200 dark:border-gray-700">
                <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                  <thead class="bg-gray-50 dark:bg-gray-900">
                    <tr>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Name
                      </th>
                      
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Slug
                      </th>
                      
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Action
                      </th>
                      
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Description
                      </th>
                      
                      <th class="relative px-6 py-3"><span class="sr-only">Actions</span></th>
                    </tr>
                  </thead>
                  
                  <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                    <tr :for={permission <- permissions}>
                      <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">
                        {permission.name}
                      </td>
                      
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                        {permission.slug}
                      </td>
                      
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                          {permission.action}
                        </span>
                      </td>
                      
                      <td class="px-6 py-4 text-sm text-gray-500 dark:text-gray-400">
                        {permission.description || "-"}
                      </td>
                      
                      <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <button
                          phx-click="edit_permission"
                          phx-value-id={permission.id}
                          class="text-violet-600 hover:text-violet-900 dark:text-violet-400 mr-4"
                        >
                          Edit
                        </button>
                        <button
                          phx-click="delete_permission"
                          phx-value-id={permission.id}
                          data-confirm="Are you sure?"
                          class="text-red-600 hover:text-red-900 dark:text-red-400"
                        >
                          Delete
                        </button>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
