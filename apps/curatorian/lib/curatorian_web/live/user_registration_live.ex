defmodule CuratorianWeb.UserRegistrationLive do
  @moduledoc """
  Registration page LiveView.

  Validates the form in real time while the user types. On submit it calls
  `Curatorian.Accounts.register_user/1` directly inside the LiveView process.
  On success it sets `trigger_submit: true`, which causes the form to fire its
  HTTP POST to `/users/log_in?_action=registered`, letting
  `CuratorianWeb.UserSessionController.create/2` open a session for the new user.
  """

  use CuratorianWeb, :live_view

  alias Curatorian.Accounts
  alias Voile.Schema.Accounts.User

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen flex items-center justify-center py-16 px-4">
        <div class="w-full max-w-md">
          <div class="card bg-base-100 shadow-xl border border-base-300">
            <div class="card-body gap-6">
              <%!-- Header --%>
              <div class="text-center">
                <h1 class="text-3xl font-bold text-primary mb-1">Create account</h1>
                <p class="text-base-content/60 text-sm">
                  Join Curatorian today
                </p>
              </div>

              <%!--
                phx-trigger-action fires a real HTTP POST once trigger_submit is true.
                The session controller then creates the session for the new user.
              --%>
              <.form
                for={@form}
                id="registration_form"
                phx-submit="save"
                phx-change="validate"
                phx-trigger-action={@trigger_submit}
                action={~p"/users/log_in?_action=registered"}
                method="post"
                class="flex flex-col gap-4"
              >
                <.input
                  field={@form[:email]}
                  type="email"
                  label="Email"
                  placeholder="you@example.com"
                  required
                  autocomplete="username"
                />

                <.input
                  field={@form[:password]}
                  type="password"
                  label="Password"
                  placeholder="at least 8 characters"
                  required
                  autocomplete="new-password"
                />

                <.button
                  type="submit"
                  class="btn btn-primary w-full"
                  phx-disable-with="Creating account…"
                >
                  Create account
                </.button>
              </.form>

              <div class="divider text-base-content/40 text-xs">Already have an account?</div>

              <.link navigate={~p"/login"} class="btn btn-outline btn-primary w-full">
                Sign in
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    # Redirect if already authenticated
    if socket.assigns.current_scope && socket.assigns.current_scope.user do
      {:ok, push_navigate(socket, to: "/")}
    else
      changeset = Accounts.change_user_registration(%User{}, %{})

      socket =
        socket
        |> assign(trigger_submit: false, check_errors: false)
        |> assign_form(changeset)

      {:ok, socket, temporary_assigns: [form: nil]}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    # Derive username from email prefix; add today's registration_date
    username = user_params["email"] |> String.split("@") |> hd()

    registration_date =
      case User.__schema__(:type, :registration_date) do
        :date -> Date.utc_today()
        _ -> Date.utc_today() |> Date.to_iso8601()
      end

    attrs =
      user_params
      |> Map.put("username", username)
      |> Map.put("registration_date", registration_date)

    case Accounts.register_user(attrs) do
      {:ok, _user} ->
        # Flip trigger_submit so the form posts to the session controller
        {:noreply,
         socket |> assign(trigger_submit: true) |> assign_form(to_form(attrs, as: :user))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(check_errors: true)
         |> assign_form(changeset)}
    end
  end

  # ---------------------------------------------------------------------------

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset, as: :user))
  end

  defp assign_form(socket, %Phoenix.HTML.Form{} = form) do
    assign(socket, form: form)
  end
end
