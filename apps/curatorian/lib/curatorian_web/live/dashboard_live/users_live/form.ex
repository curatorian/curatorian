defmodule CuratorianWeb.DashboardLive.UsersLive.Form do
  use CuratorianWeb, :live_view_dashboard

  alias Voile.Schema.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <.header>
        {@page_title}
        <:subtitle>
          {if @live_action == :new, do: "Create a new user", else: "Edit user details"}
        </:subtitle>
      </.header>

      <div class="mt-6 bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 md:p-8">
        <.form
          for={@form}
          id="user-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-6"
        >
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <.input field={@form[:username]} type="text" label="Username" required />
            <.input field={@form[:email]} type="email" label="Email" required />
            <.input field={@form[:fullname]} type="text" label="Full Name" />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              required={@live_action == :new}
            />
          </div>

          <div class="flex items-center justify-between pt-6 border-t border-gray-200 dark:border-gray-700">
            <.button
              type="button"
              navigate={~p"/dashboard/admin/users"}
              class="btn-secondary"
            >
              <.icon name="hero-x-mark" class="w-4 h-4 mr-2" /> Cancel
            </.button>
            <.button type="submit" phx-disable-with="Saving...">
              <.icon name="hero-check" class="w-4 h-4 mr-2" /> {if @live_action == :new,
                do: "Create User",
                else: "Update User"}
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
    user = Accounts.get_user(id)

    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, user)
    |> assign(:form, to_form(Accounts.change_user(user)))
  end

  defp apply_action(socket, :new, _params) do
    user = %Voile.Schema.Accounts.User{}

    socket
    |> assign(:page_title, "New User")
    |> assign(:user, user)
    |> assign(:form, to_form(Accounts.change_user(user)))
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.live_action, user_params)
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_navigate(to: ~p"/dashboard/admin/users")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_navigate(to: ~p"/dashboard/admin/users")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end
end
