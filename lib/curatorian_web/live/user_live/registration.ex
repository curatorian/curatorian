defmodule CuratorianWeb.UserLive.Registration do
  use CuratorianWeb, :live_view

  alias Curatorian.Accounts
  alias Curatorian.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <div class="text-center">
          <.header>
            Register for an account
            <:subtitle>
              Already registered?
              <.link navigate={~p"/login"} class="font-semibold text-brand hover:underline">
                Log in
              </.link>
              to your account now.
            </:subtitle>
          </.header>
        </div>
        
        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="email"
            required
          />
          <.button phx-disable-with="Creating account..." class="btn btn-primary w-full">
            Create an account
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: CuratorianWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    # Use the registration changeset so username and password fields
    # are present and validated on the LiveView form.
    changeset = Accounts.change_user_registration(%User{}, %{})

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    username = Map.get(user_params, "email", "") |> String.split("@") |> hd()
    user_params = Map.put(user_params, "username", username)

    case Accounts.register_user_by_email_only(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/login/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(:email, user.email)
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/login")}

      {:error, %Ecto.Changeset{} = changeset} ->
        # Handle user changeset error with additional data
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
