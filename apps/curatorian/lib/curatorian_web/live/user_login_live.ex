defmodule CuratorianWeb.UserLoginLive do
  @moduledoc """
  Login page LiveView.

  Renders the login form. Form submission is handled by
  `CuratorianWeb.UserSessionController.create/2` via a regular HTTP POST
  (the form uses `action={~p"/users/log_in"}` so Phoenix processes it as a
  controller action, not a LiveView event). This keeps CSRF protection intact
  and allows one consistent redirect after login.
  """

  use CuratorianWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen flex items-center justify-center py-16 px-4">
        <div class="w-full max-w-md">
          <div class="card bg-base-100 shadow-xl border border-base-300">
            <div class="card-body gap-6">
              <%!-- Header --%>
              <div class="text-center">
                <h1 class="text-3xl font-bold text-primary mb-1">Sign in</h1>
                <p class="text-base-content/60 text-sm">
                  Welcome back to Curatorian
                </p>
              </div>

              <%!-- Login form — submitted to the session controller via HTTP POST --%>
              <.form
                for={@form}
                id="login_form"
                action={~p"/users/log_in"}
                class="flex flex-col gap-4"
              >
                <.input
                  field={@form[:email]}
                  type="text"
                  label="Email, username, or identifier"
                  placeholder="you@example.com"
                  required
                  autocomplete="username"
                />

                <.input
                  field={@form[:password]}
                  type="password"
                  label="Password"
                  placeholder="••••••••"
                  required
                  autocomplete="current-password"
                />

                <div class="flex items-center justify-between">
                  <label class="flex items-center gap-2 cursor-pointer select-none text-sm">
                    <input
                      type="checkbox"
                      name="user[remember_me]"
                      value="true"
                      class="checkbox checkbox-primary checkbox-sm"
                    />
                    <span>Remember me</span>
                  </label>

                  <%!-- TODO: add /users/reset_password route when password-reset LiveView is built --%>
                </div>

                <.button type="submit" class="btn btn-primary w-full" phx-disable-with="Signing in…">
                  Sign in
                </.button>
              </.form>

              <div class="divider text-base-content/40 text-xs">Don't have an account?</div>

              <.link
                navigate={~p"/register"}
                class="btn btn-outline btn-primary w-full"
              >
                Create an account
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
      email = Phoenix.Flash.get(socket.assigns.flash, :email)
      form = to_form(%{"email" => email}, as: :user)
      {:ok, assign(socket, form: form), temporary_assigns: [form: nil]}
    end
  end
end
