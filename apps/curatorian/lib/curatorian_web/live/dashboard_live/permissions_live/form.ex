defmodule CuratorianWeb.DashboardLive.PermissionsLive.Form do
  use CuratorianWeb, :live_view_dashboard

  alias VoileWeb.Auth.PermissionManager
  alias Voile.Schema.Accounts.Permission

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <.header>
        {@page_title}
        <:subtitle>
          {if @live_action == :new, do: "Create a new permission", else: "Edit permission details"}
        </:subtitle>
      </.header>

      <div class="mt-6 bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 md:p-8">
        <.form
          for={@form}
          id="permission-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-6"
        >
          <div class="space-y-6">
            <.input field={@form[:name]} type="text" label="Permission Name" required />
            <.input field={@form[:resource]} type="text" label="Resource" required />
            <.input field={@form[:action]} type="text" label="Action" required />
            <.input field={@form[:description]} type="textarea" label="Description" rows="3" />
          </div>

          <div class="flex items-center justify-between pt-6 border-t border-gray-200 dark:border-gray-700">
            <.button
              type="button"
              navigate={~p"/dashboard/admin/permissions"}
              class="btn-secondary"
            >
              <.icon name="hero-x-mark" class="w-4 h-4 mr-2" /> Cancel
            </.button>
            <.button type="submit" phx-disable-with="Saving...">
              <.icon name="hero-check" class="w-4 h-4 mr-2" /> {if @live_action == :new,
                do: "Create Permission",
                else: "Update Permission"}
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
    permission = PermissionManager.get_permission(String.to_integer(id))

    socket
    |> assign(:page_title, "Edit Permission")
    |> assign(:permission, permission)
    |> assign(:form, to_form(Permission.changeset(permission, %{})))
  end

  defp apply_action(socket, :new, _params) do
    permission = %Permission{}

    socket
    |> assign(:page_title, "New Permission")
    |> assign(:permission, permission)
    |> assign(:form, to_form(Permission.changeset(permission, %{})))
  end

  @impl true
  def handle_event("validate", %{"permission" => permission_params}, socket) do
    changeset =
      socket.assigns.permission
      |> Permission.changeset(permission_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"permission" => permission_params}, socket) do
    save_permission(socket, socket.assigns.live_action, permission_params)
  end

  defp save_permission(socket, :edit, permission_params) do
    case PermissionManager.update_permission(socket.assigns.permission, permission_params) do
      {:ok, _permission} ->
        {:noreply,
         socket
         |> put_flash(:info, "Permission updated successfully")
         |> push_navigate(to: ~p"/dashboard/admin/permissions")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp save_permission(socket, :new, permission_params) do
    case PermissionManager.create_permission(permission_params) do
      {:ok, _permission} ->
        {:noreply,
         socket
         |> put_flash(:info, "Permission created successfully")
         |> push_navigate(to: ~p"/dashboard/admin/permissions")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end
end
