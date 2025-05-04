defmodule CuratorianWeb.MemberLoginLive do
  use CuratorianWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen">
      <div class="pt-32 text-center">
        <.header>
          Masuk atau Daftar ke Curatorian
        </.header>
      </div>

      <div class="flex gap-10 items-center justify-center mt-5">
        <div class="w-full max-w-sm">
          <.simple_form for={@form} id="login_form" action="/users/log_in" phx-update="ignore">
            <.input field={@form[:email]} type="email" label="Email" required />
            <.input field={@form[:password]} type="password" label="Password" required />

            <:actions>
              <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
              <.link
                href="/users/reset_password"
                class="text-sm font-semibold no-underline hover:underline"
              >
                Lupa Password
              </.link>
            </:actions>
            <:actions>
              <.button phx-disable-with="Logging in..." class="w-full">
                Log in <span aria-hidden="true">→</span>
              </.button>
            </:actions>
          </.simple_form>
          <.link
            navigate={~p"/users/register"}
            class="text-sm font-semibold no-underline hover:underline"
            id="register_link"
          >
            Daftar akun baru &rightarrow;
          </.link>
        </div>
        <div class="h-xl">
          <div class="w-px h-96 bg-violet-300 mx-4"></div>
        </div>
        <div>
          <img src="/images/undraw_fingerprint-login.png" class="h-[17rem]" />
          <.button phx-click="google_auth" class="bg-violet-100 w-full">
            Login with Google
          </.button>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    conn = nil
    {:ok, assign(socket, form: form, conn: conn), temporary_assigns: [form: form]}
  end

  def handle_event("google_auth", _params, socket) do
    {:noreply, socket |> redirect(to: "/auth/google")}
  end
end
