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

  require Logger

  alias Curatorian.Accounts
  alias Turnstile
  alias Voile.Schema.Accounts.User

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex justify-center px-4 py-6">
        <div class="w-full max-w-4xl">
          <div class="card bg-base-100 shadow-xl border border-base-300 overflow-hidden">
            <div class="grid grid-cols-1 lg:grid-cols-5">
              <%!-- Brand panel --%>
              <div class="hidden lg:flex lg:col-span-2 bg-primary flex-col justify-between p-8 relative overflow-hidden">
                <%!-- Decorative background shapes --%>
                <div class="absolute -top-10 -right-10 w-48 h-48 rounded-full bg-primary-content/5 pointer-events-none">
                </div>
                <div class="absolute -bottom-14 -left-6 w-56 h-56 rounded-full bg-primary-content/5 pointer-events-none">
                </div>

                <div class="relative z-10">
                  <div class="flex items-center gap-2 mb-10">
                    <div class="w-9 h-9 rounded-full bg-primary-content/15 flex items-center justify-center">
                      <.icon name="hero-book-open" class="size-4 text-primary-content" />
                    </div>
                    <span class="font-semibold text-primary-content tracking-wide">Curatorian</span>
                  </div>

                  <h2 class="text-2xl font-serif font-semibold text-primary-content leading-snug mb-3">
                    Bergabunglah dengan komunitas Kurator.
                  </h2>
                  <p class="text-sm text-primary-content/70 leading-relaxed">
                    Buat akun Anda dan mulai kelola koleksi GLAM dengan alat yang dirancang sesuai cara Anda bekerja.
                  </p>
                </div>

                <div class="relative z-10 space-y-3 mt-8">
                  <div class="flex items-center gap-2 text-sm text-primary-content/80">
                    <.icon name="hero-check-circle" class="size-4 text-primary-content/60 shrink-0" />
                    <span>Gratis untuk memulai</span>
                  </div>
                  <div class="flex items-center gap-2 text-sm text-primary-content/80">
                    <.icon name="hero-check-circle" class="size-4 text-primary-content/60 shrink-0" />
                    <span>Tanpa batas katalog</span>
                  </div>
                  <div class="flex items-center gap-2 text-sm text-primary-content/80">
                    <.icon name="hero-check-circle" class="size-4 text-primary-content/60 shrink-0" />
                    <span>Dibuat untuk GLAM Indonesia</span>
                  </div>
                </div>
              </div>

              <%!-- Form panel --%>
              <div class="col-span-1 lg:col-span-3 p-8 lg:p-10 flex flex-col justify-center">
                <div class="mb-7">
                  <h1 class="text-2xl font-semibold text-base-content mb-1">Buat akun Anda</h1>
                  <p class="text-sm text-base-content/60">
                    Bergabung dengan Curatorian hari ini
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
                  class="flex flex-col gap-5"
                >
                  <.input
                    field={@form[:email]}
                    type="email"
                    label="Email"
                    placeholder="chrisna@curatorian.id"
                    required
                    autocomplete="username"
                  />

                  <.input
                    field={@form[:password]}
                    type="password"
                    label="Kata sandi"
                    placeholder="minimal 12 karakter"
                    required
                    autocomplete="new-password"
                  />

                  <div style="display:none" aria-hidden="true">
                    <input type="text" name="user[website]" tabindex="-1" autocomplete="off" />
                  </div>

                  <.captcha
                    id="registration_turnstile"
                    theme={@turnstile_theme}
                    events={[:success, :error, :expired]}
                    captcha_valid={@captcha_valid}
                  />

                  <.button
                    type="submit"
                    class={"btn btn-primary w-full gap-2 motion-safe:transition-all motion-safe:duration-200" <> if(!@captcha_valid, do: " btn-disabled opacity-50", else: "")}
                    phx-disable-with="Membuat akun…"
                    disabled={!@captcha_valid}
                  >
                    Buat akun <.icon name="hero-arrow-right" class="size-4" />
                  </.button>
                </.form>

                <div class="divider text-base-content/30 text-xs my-5">atau lanjutkan dengan</div>

                <%!-- OAuth registration — disabled until Turnstile captcha passes --%>
                <a
                  href={if @captcha_valid, do: "/auth/google", else: "#"}
                  aria-disabled={!@captcha_valid}
                  tabindex={if @captcha_valid, do: "0", else: "-1"}
                  class={[
                    "btn btn-outline w-full gap-2 border-base-300 motion-safe:transition-all motion-safe:duration-200",
                    if(@captcha_valid,
                      do: "hover:bg-base-200",
                      else: "opacity-50 pointer-events-none cursor-not-allowed"
                    )
                  ]}
                >
                  <svg class="size-4" viewBox="0 0 24 24" aria-hidden="true">
                    <path
                      d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                      fill="#4285F4"
                    />
                    <path
                      d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                      fill="#34A853"
                    />
                    <path
                      d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                      fill="#FBBC05"
                    />
                    <path
                      d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                      fill="#EA4335"
                    />
                  </svg>
                  Daftar dengan Google
                </a>

                <p class="text-center text-sm text-base-content/60 mt-6">
                  Sudah punya akun?
                  <.link
                    navigate={~p"/login"}
                    class="text-primary font-medium hover:underline underline-offset-2 ml-1"
                  >
                    Masuk
                  </.link>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    remote_ip =
      socket
      |> get_connect_info(:peer_data)
      |> case do
        %{address: address} -> address
        _ -> nil
      end

    # Redirect if already authenticated
    if socket.assigns.current_scope && socket.assigns.current_scope.user do
      {:ok, push_navigate(socket, to: "/")}
    else
      changeset = Accounts.change_user_registration(%User{}, %{})

      socket =
        socket
        |> assign(check_errors: false)
        |> assign_form(changeset)
        |> assign(:captcha_valid, false)
        |> assign(:turnstile_theme, "light")
        |> assign(:remote_ip, remote_ip)

      {:ok, socket, temporary_assigns: [form: nil]}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("save", %{"user" => user_params} = params, socket) do
    if Map.get(user_params, "website", "") != "" do
      # Honeypot triggered (likely bot). Refresh captcha and block.
      {:noreply,
       socket
       |> put_flash(:error, "Bot detection triggered. Please try again.")
       |> assign(captcha_valid: false)
       |> Turnstile.refresh()}
    else
      with {:ok, _} <- Turnstile.verify(params, socket.assigns.remote_ip) do
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
          {:ok, user} ->
            confirmation_result =
              Accounts.deliver_user_confirmation_instructions(
                user,
                &url(~p"/users/confirm/#{&1}")
              )

            case confirmation_result do
              {:ok, _} ->
                {:noreply,
                 socket
                 |> put_flash(
                   :info,
                   "Account created! Please check your email to confirm your address."
                 )
                 |> push_navigate(to: ~p"/users/pending_confirmation?email=#{user.email}")}

              {:error, reason} ->
                Logger.error("Failed to deliver confirmation email: #{inspect(reason)}")

                {:noreply,
                 socket
                 |> put_flash(
                   :warning,
                   "Account created, but we couldn't send the confirmation email right now. Please try resending from the confirmation page."
                 )
                 |> push_navigate(to: ~p"/users/pending_confirmation?email=#{user.email}")}
            end

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply,
             socket
             |> assign(check_errors: true)
             |> assign_form(changeset)}
        end
      else
        {:error, _} ->
          {:noreply,
           socket
           |> put_flash(:error, "Turnstile verification failed, please try again.")
           |> assign(captcha_valid: false)
           |> Turnstile.refresh()}
      end
    end
  end

  def handle_event("turnstile:success", _params, socket) do
    {:noreply, assign(socket, :captcha_valid, true)}
  end

  def handle_event("turnstile:error", _params, socket) do
    {:noreply, assign(socket, :captcha_valid, false)}
  end

  def handle_event("turnstile:expired", _params, socket) do
    {:noreply, assign(socket, :captcha_valid, false)}
  end

  # ---------------------------------------------------------------------------

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, form: to_form(changeset, as: :user))
  end
end
