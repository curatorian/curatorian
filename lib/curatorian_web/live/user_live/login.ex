defmodule CuratorianWeb.UserLive.Login do
  use CuratorianWeb, :live_view

  alias Curatorian.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen flex items-center justify-center p-6">
        <div class="w-full max-w-4xl grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
          <div
            id="login-card"
            class="bg-base-100 rounded-xl shadow-lg p-8 md:p-10 opacity-0 translate-y-4 transition-all duration-500"
            phx-mounted={JS.remove_class("opacity-0 translate-y-4", to: "#login-card")}
          >
            <div class="text-center mb-6">
              <.header>
                <p class="text-2xl">Log in</p>
                
                <:subtitle>
                  <%= if @current_scope do %>
                    You need to reauthenticate to perform sensitive actions on your account.
                  <% else %>
                    Don't have an account? <.link
                      navigate={~p"/register"}
                      class="font-semibold text-brand hover:underline"
                      phx-no-format
                    >Sign up</.link> for an account now.
                  <% end %>
                </:subtitle>
              </.header>
            </div>
            
            <div :if={local_mail_adapter?()} class="alert alert-info mb-4">
              <.icon name="hero-information-circle" class="size-6 shrink-0" />
              <div>
                <p class="font-medium">You are running the local mail adapter.</p>
                
                <p class="mt-1 text-sm">
                  To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
                </p>
              </div>
            </div>
             {local_mail_adapter?()}
            <.form
              :let={f}
              for={@form}
              id="login_form_magic"
              action={~p"/login"}
              phx-submit="submit_magic"
              class="space-y-4"
            >
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                required
                phx-mounted={JS.focus()}
              />
              <.button class="btn btn-primary w-full">
                Log in with email <span aria-hidden="true">→</span>
              </.button>
            </.form>
            
            <div class="divider">or</div>
            
            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/login"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
              class="space-y-4"
            >
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                required
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                autocomplete="current-password"
              />
              <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
                Log in and stay logged in <span aria-hidden="true">→</span>
              </.button>
              <.button class="btn btn-primary btn-soft w-full mt-2">Log in only this time</.button>
            </.form>
            <!-- Mobile Google button (visible on small screens) -->
            <div class="md:hidden mt-4">
              <button
                phx-click="google_auth"
                type="button"
                class="w-full inline-flex items-center justify-center gap-3 px-4 py-2 border rounded-full bg-white text-sm shadow-sm hover:shadow-md transition"
              >
                <svg
                  class="w-5 h-5"
                  viewBox="0 0 48 48"
                  xmlns="http://www.w3.org/2000/svg"
                  aria-hidden="true"
                >
                  <path
                    fill="#EA4335"
                    d="M24 9.5c3.54 0 6.24 1.53 8.12 2.78l6-6C35.94 3.06 30.36 1 24 1 14.73 1 6.98 6.94 3.7 14.7l7.94 6.16C13.9 15.1 18.46 9.5 24 9.5z"
                  />
                  <path
                    fill="#34A853"
                    d="M46.5 24.5c0-1.62-.15-2.84-.47-4.08H24v8.02h12.9c-.56 3.06-3.56 8.88-12.9 8.88-7.23 0-13.07-5.96-13.07-13.28 0-7.32 5.84-13.28 13.07-13.28 4.14 0 6.9 1.76 8.5 3.28l6.9-6.7C40.18 4.6 33.64 1 24 1 11.85 1 2.3 10.07 0 22.5l7.94 6.16C10.32 18.1 16.6 9.5 24 9.5c3.54 0 6.24 1.53 8.12 2.78l6-6C35.94 3.06 30.36 1 24 1 14.73 1 6.98 6.94 3.7 14.7l7.94 6.16C13.9 15.1 18.46 9.5 24 9.5z"
                  />
                </svg>
                Sign in with Google
              </button>
            </div>
          </div>
          
          <div class="hidden md:flex flex-col items-center justify-center gap-6">
            <img
              src="/images/undraw_fingerprint-login.png"
              class="w-full max-w-md rounded-lg shadow-md"
            />
            <button
              phx-click="google_auth"
              type="button"
              class="inline-flex items-center gap-3 px-5 py-3 rounded-full bg-white text-sm shadow-md hover:shadow-lg transition"
            >
              <svg
                class="w-5 h-5"
                viewBox="0 0 533.5 544.3"
                xmlns="http://www.w3.org/2000/svg"
                aria-hidden="true"
              >
                <path
                  fill="#4285F4"
                  d="M533.5 278.4c0-17.4-1.4-34.1-4.1-50.3H272v95.6h146.9c-6.3 34-25 62.8-53.4 82v68.1h86.3c50.5-46.6 81.7-115.2 81.7-195.4z"
                />
                <path
                  fill="#34A853"
                  d="M272 544.3c72.9 0 134.2-24.1 178.9-65.6l-86.3-68.1c-24.1 16.2-55 25.8-92.6 25.8-71 0-131.2-47.9-152.7-112.2H32.1v70.5C76.6 491.2 168.6 544.3 272 544.3z"
                />
                <path
                  fill="#FBBC05"
                  d="M119.3 323.9c-10.8-32.3-10.8-66.9 0-99.2V154.2H32.1c-39.3 77.2-39.3 168.7 0 245.9l87.2-76.2z"
                />
                <path
                  fill="#EA4335"
                  d="M272 107.5c38.6 0 73.4 13.3 100.8 39.3l75.5-75.5C406.8 24.9 345.5 0 272 0 168.6 0 76.6 53.1 32.1 154.2l87.2 70.5C140.8 155.4 201 107.5 272 107.5z"
                />
              </svg> <span class="font-medium">Continue with Google</span>
            </button>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/login/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/login")}
  end

  defp local_mail_adapter? do
    Application.get_env(:curatorian, Curatorian.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
