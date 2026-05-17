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

  alias Turnstile

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
                    Platform Komunitasmu, dikelola dengan cermat.
                  </h2>
                  <p class="text-sm text-primary-content/70 leading-relaxed">
                    Dibuat oleh Kurator untuk Kurator. Kelola koleksi, komunitas, dan katalog — semua dalam satu tempat.
                  </p>
                </div>

                <div class="relative z-10 space-y-3 mt-8">
                  <div class="flex items-center gap-2 text-sm text-primary-content/80">
                    <.icon name="hero-check-circle" class="size-4 text-primary-content/60 shrink-0" />
                    <span>Manajemen katalog yang cerdas</span>
                  </div>
                  <div class="flex items-center gap-2 text-sm text-primary-content/80">
                    <.icon name="hero-check-circle" class="size-4 text-primary-content/60 shrink-0" />
                    <span>Alat komunitas & kurasi</span>
                  </div>
                  <div class="flex items-center gap-2 text-sm text-primary-content/80">
                    <.icon name="hero-check-circle" class="size-4 text-primary-content/60 shrink-0" />
                    <span>Standar perpustakaan Indonesia</span>
                  </div>
                </div>
              </div>

              <%!-- Form panel --%>
              <div class="col-span-1 lg:col-span-3 p-8 lg:p-10 flex flex-col justify-center">
                <div class="mb-7">
                  <h1 class="text-2xl font-semibold text-base-content mb-1">Selamat datang kembali</h1>
                  <p class="text-sm text-base-content/60">
                    Masuk ke akun Curatorian Anda
                  </p>
                </div>

                <%!-- Login form — submitted to the session controller via HTTP POST --%>
                <.form
                  for={@form}
                  id="login_form"
                  action={~p"/login"}
                  class="flex flex-col gap-5"
                >
                  <.input
                    field={@form[:email]}
                    type="text"
                    label="Email, nama pengguna, atau pengenal"
                    placeholder="chrisna@curatorian.id"
                    required
                    autocomplete="username"
                  />

                  <.input
                    field={@form[:password]}
                    type="password"
                    label="Kata sandi"
                    placeholder="••••••••"
                    required
                    autocomplete="current-password"
                  />

                  <div class="flex items-center justify-between">
                    <label class="flex items-center gap-2 cursor-pointer select-none text-sm text-base-content/70">
                      <input
                        type="checkbox"
                        name="user[remember_me]"
                        value="true"
                        class="checkbox checkbox-primary checkbox-sm"
                      />
                      <span>Ingat saya</span>
                    </label>
                    <%!-- TODO: add /users/reset_password route when password-reset LiveView is built --%>
                  </div>

                  <.captcha
                    id="login_turnstile"
                    theme={@turnstile_theme}
                    events={[:success, :error, :expired]}
                    captcha_valid={@captcha_valid}
                  />

                  <.button
                    type="submit"
                    class={"btn btn-primary w-full gap-2 motion-safe:transition-all motion-safe:duration-200" <> if(!@captcha_valid, do: " btn-disabled opacity-50", else: "")}
                    phx-disable-with="Sedang masuk…"
                    disabled={!@captcha_valid}
                  >
                    Masuk
                    <.icon name="hero-arrow-right" class="size-4" />
                  </.button>
                </.form>

                <div class="divider text-base-content/30 text-xs my-5">atau lanjutkan dengan</div>

                <%!-- OAuth login — disabled until Turnstile captcha passes --%>
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
                  Masuk dengan Google
                </a>

                <p class="text-center text-sm text-base-content/60 mt-6">
                  Belum punya akun?
                  <.link
                    navigate={~p"/register"}
                    class="text-primary font-medium hover:underline underline-offset-2 ml-1"
                  >
                    Daftar sekarang
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
      email = Phoenix.Flash.get(socket.assigns.flash, :email)
      form = to_form(%{"email" => email}, as: :user)

      socket =
        socket
        |> assign(form: form)
        |> assign(captcha_valid: false)
        |> assign(turnstile_theme: "light")
        |> assign(remote_ip: remote_ip)

      {:ok, socket, temporary_assigns: [form: nil]}
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
end
