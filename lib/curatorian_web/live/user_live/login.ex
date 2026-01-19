defmodule CuratorianWeb.UserLive.Login do
  use CuratorianWeb, :live_view

  alias Curatorian.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen flex justify-center p-6">
        <div class="w-full max-w-4xl">
          <!-- Header Information -->
          <div class="text-center mb-8">
            <h1 class="text-3xl md:text-4xl font-bold text-gray-900 dark:text-white mb-3">
              Selamat Datang Kembali di Curatorian
            </h1>

            <p class="text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
              Masuk untuk mengakses koleksi kurasi Anda, mengelola profil, dan terhubung dengan komunitas kurator.
            </p>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
            <div
              id="login-card"
              class="bg-gradient-to-br from-violet-50 to-purple-50 dark:from-gray-800 dark:to-gray-500 rounded-xl shadow-lg p-8 md:p-10 opacity-0 translate-y-4 transition-all duration-500 border-2 border-violet-100 dark:border-gray-600"
              phx-mounted={JS.remove_class("opacity-0 translate-y-4", to: "#login-card")}
            >
              <div class="text-center mb-6">
                <.header>
                  <p class="text-2xl dark:text-white">Masuk</p>

                  <:subtitle>
                    <%= if @current_scope do %>
                      Anda perlu mengautentikasi ulang untuk melakukan tindakan sensitif pada akun Anda.
                    <% else %>
                      Belum punya akun? <.link
                        navigate={~p"/register"}
                        class="font-semibold text-brand hover:underline"
                        phx-no-format
                      >Daftar</.link> sekarang.
                    <% end %>
                  </:subtitle>
                </.header>
              </div>

              <div :if={local_mail_adapter?()} class="alert alert-info mb-4">
                <.icon name="hero-information-circle" class="size-6 shrink-0" />
                <div>
                  <p class="font-medium">Anda menggunakan adaptor email lokal.</p>

                  <p class="mt-1 text-sm">
                    Untuk melihat email yang terkirim, kunjungi <.link
                      href="/dev/mailbox"
                      class="underline"
                    >halaman kotak surat</.link>.
                  </p>
                </div>
              </div>
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
                  Masuk dengan email <span aria-hidden="true">→</span>
                </.button>
              </.form>

              <div class="divider">atau</div>

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
                  label="Kata Sandi"
                  autocomplete="current-password"
                />
                <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
                  Masuk dan tetap login <span aria-hidden="true">→</span>
                </.button>
                <.button class="btn btn-primary btn-soft w-full mt-2">
                  Masuk untuk sesi ini saja
                </.button>
              </.form>
              <!-- Mobile Google button (visible on small screens) -->
              <div class="md:hidden mt-6">
                <div class="relative">
                  <div class="absolute inset-0 flex items-center" aria-hidden="true">
                    <div class="w-full border-t border-gray-300 dark:border-gray-600"></div>
                  </div>

                  <div class="relative flex justify-center text-sm">
                    <span class="px-4 bg-gradient-to-br from-violet-50 to-purple-50 dark:from-gray-800 dark:to-gray-700 text-gray-500 dark:text-gray-400 font-medium">
                      Masuk Cepat
                    </span>
                  </div>
                </div>

                <div class="mt-6 p-4 bg-gradient-to-br from-violet-50 to-purple-50 dark:from-gray-700 dark:to-gray-600 rounded-xl border-2 border-violet-100 dark:border-gray-600">
                  <p class="text-xs text-center text-gray-600 dark:text-gray-300 mb-3 font-medium">
                    🚀 Autentikasi sekali klik dengan akun Google Anda
                  </p>

                  <button
                    phx-click="google_auth"
                    type="button"
                    class="w-full inline-flex items-center justify-center gap-3 px-4 py-3 border-2 border-gray-300 dark:border-gray-500 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-base font-semibold shadow-sm hover:shadow-lg hover:scale-105 transition-all duration-200"
                  >
                    <svg
                      class="w-6 h-6"
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
                    Masuk dengan Google
                  </button>
                </div>
              </div>
            </div>

            <div class="hidden md:flex flex-col items-center justify-center gap-6">
              <div class="text-center mb-4">
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">
                  Autentikasi Aman
                </h2>

                <p class="text-gray-600 dark:text-gray-400 max-w-sm mx-auto">
                  Pilih metode login pilihan Anda—baik melalui tautan ajaib email atau Google OAuth—untuk pengalaman yang lancar dan aman.
                </p>
              </div>

              <div class="w-full max-w-md p-6 bg-gradient-to-br from-violet-50 to-purple-50 dark:from-gray-700 dark:to-gray-600 rounded-2xl border-2 border-violet-100 dark:border-gray-600 shadow-lg">
                <div class="text-center mb-4">
                  <p class="text-sm font-medium text-gray-700 dark:text-gray-200 mb-1">
                    ⚡ Masuk Cepat & Mudah
                  </p>

                  <p class="text-xs text-gray-600 dark:text-gray-400">
                    Gunakan akun Google Anda yang sudah ada
                  </p>
                </div>

                <button
                  phx-click="google_auth"
                  type="button"
                  class="w-full inline-flex items-center justify-center gap-3 px-6 py-4 rounded-xl bg-white dark:bg-gray-700 text-gray-900 dark:text-white border-2 border-gray-300 dark:border-gray-500 text-base font-semibold shadow-md hover:shadow-xl hover:scale-105 transition-all duration-200"
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
                  </svg>
                   <span class="font-semibold">Lanjutkan dengan Google</span>
                </button>
                <p class="text-xs text-center text-gray-500 dark:text-gray-400 mt-4">
                  🔒 Diamankan oleh sistem autentikasi Google
                </p>
              </div>
            </div>
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

  def handle_event("google_auth", _params, socket) do
    {:noreply, push_navigate(socket, to: "/auth/google")}
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
