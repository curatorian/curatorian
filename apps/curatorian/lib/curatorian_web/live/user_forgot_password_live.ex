defmodule CuratorianWeb.UserForgotPasswordLive do
  @moduledoc """
  "Forgot password" page — sends a password-reset link to the given email.

  Never reveals whether an account exists. Throttled per email to prevent
  email bombing.
  """

  use CuratorianWeb, :live_view

  alias Curatorian.Accounts
  alias Curatorian.RateLimiter

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex justify-center px-4 py-6">
        <div class="w-full max-w-lg">
          <div class="card bg-base-100 shadow-xl border border-base-300 overflow-hidden">
            <div class="h-1.5 w-full bg-primary"></div>

            <div class="card-body gap-6 p-8 lg:p-10">
              <%!-- Header --%>
              <div class="flex flex-col items-center text-center gap-3">
                <div class="w-16 h-16 rounded-full bg-primary/15 flex items-center justify-center">
                  <.icon name="hero-key" class="size-7 text-primary" />
                </div>
                <div>
                  <h1 class="text-2xl font-semibold text-base-content mb-1">Lupa kata sandi?</h1>
                  <p class="text-sm text-base-content/60 max-w-xs mx-auto">
                    Masukkan email akun Anda dan kami akan mengirim tautan aman untuk
                    mengatur ulang kata sandi.
                  </p>
                </div>
              </div>

              <.form for={@form} id="forgot-password-form" phx-submit="send_email">
                <div class="space-y-4">
                  <.input
                    field={@form[:email]}
                    type="email"
                    label="Email"
                    placeholder="nama@email.com"
                    required
                  />

                  <.button type="submit" class="btn btn-primary w-full" phx-disable-with="Mengirim…">
                    Kirim tautan atur ulang
                  </.button>
                </div>
              </.form>

              <div class="text-center text-sm text-base-content/60">
                Sudah ingat kata sandinya?
                <.link navigate={~p"/login"} class="link link-primary">
                  Masuk di sini
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    # Logged-in users don't need this page.
    current_scope = socket.assigns[:current_scope]

    if is_map(current_scope) && current_scope.user do
      {:ok, push_navigate(socket, to: ~p"/foyer")}
    else
      {:ok, assign(socket, form: to_form(%{}, as: :user))}
    end
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    email_key = String.downcase(String.trim(email))

    with :ok <- RateLimiter.check(:forgot_password, email_key, 3, 3600),
         {:ok, _} <- deliver_if_resettable(email) do
      # One neutral message for every outcome — never reveal whether the
      # account exists.
      {:noreply,
       socket
       |> put_flash(
         :info,
         "Jika email tersebut terdaftar, tautan atur ulang kata sandi telah dikirim."
       )
       |> redirect(to: ~p"/login")}
    else
      {:error, :rate_limited} ->
        {:noreply,
         socket
         |> put_flash(:error, "Terlalu banyak permintaan. Silakan coba lagi nanti.")}

      {:error, reason} ->
        require Logger

        Logger.error("Failed to deliver reset password email: #{inspect(reason)}")

        {:noreply,
         socket
         |> put_flash(
           :warning,
           "Jika email tersebut terdaftar, tautan atur ulang kata sandi telah dikirim."
         )
         |> redirect(to: ~p"/login")}
    end
  end

  defp deliver_if_resettable(email) do
    case Accounts.get_user_by_email(email) do
      nil ->
        # Pretend success — identical timing/message as the real path.
        {:ok, %{sent: false}}

      user ->
        Accounts.deliver_user_reset_password_instructions(
          user,
          &url(~p"/users/reset_password/#{&1}")
        )
    end
  end
end
