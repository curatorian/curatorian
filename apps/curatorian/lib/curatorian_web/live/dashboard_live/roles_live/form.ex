defmodule CuratorianWeb.DashboardLive.RolesLive.Form do
  use CuratorianWeb, :live_view_dashboard

  alias VoileWeb.Auth.PermissionManager
  alias Voile.Schema.Accounts.Role

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <.header>
        {@page_title}
        <:subtitle>
          {if @live_action == :new, do: "Create a new role", else: "Edit role details"}
        </:subtitle>
      </.header>

      <div class="mt-6 bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 md:p-8">
        <.form
          for={@form}
          id="role-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-6"
        >
          <div class="space-y-6">
            <.input field={@form[:name]} type="text" label="Role Name" required />
            <.input field={@form[:description]} type="textarea" label="Description" rows="3" />
            <.input
              field={@form[:is_system_role]}
              type="checkbox"
              label="System Role (cannot be edited by regular admins)"
            />
          </div>

          <div class="flex items-center justify-between pt-6 border-t border-gray-200 dark:border-gray-700">
            <.button
              type="button"
              navigate={~p"/dashboard/admin/roles"}
              class="btn-secondary"
            >
              <.icon name="hero-x-mark" class="w-4 h-4 mr-2" /> Cancel
            </.button>
            <.button type="submit" phx-disable-with="Saving...">
              <.icon name="hero-check" class="w-4 h-4 mr-2" /> {if @live_action == :new,
                do: "Create Role",
                else: "Update Role"}
            </.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    role = PermissionManager.get_role(String.to_integer(id))

    socket
    |> assign(:page_title, "Edit Role")
    |> assign(:role, role)
    |> assign(:form, to_form(Role.changeset(role, %{})))
  end

  defp apply_action(socket, :new, _params) do
    role = %Voile.Schema.Accounts.Role{}

    socket
    |> assign(:page_title, "New Role")
    |> assign(:role, role)
    |> assign(:form, to_form(Role.changeset(role, %{})))
  end

  @impl true
  def handle_event("validate", %{"role" => role_params}, socket) do
    changeset =
      socket.assigns.role
      |> Role.changeset(role_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"role" => role_params}, socket) do
    save_role(socket, socket.assigns.live_action, role_params)
  end

  defp save_role(socket, :edit, role_params) do
    case PermissionManager.update_role(socket.assigns.role, role_params) do
      {:ok, _role} ->
        {:noreply,
         socket
         |> put_flash(:info, "Role updated successfully")
         |> push_navigate(to: ~p"/dashboard/admin/roles")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp save_role(socket, :new, role_params) do
    case PermissionManager.create_role(role_params) do
      {:ok, _role} ->
        {:noreply,
         socket
         |> put_flash(:info, "Role created successfully")
         |> push_navigate(to: ~p"/dashboard/admin/roles")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end
end
