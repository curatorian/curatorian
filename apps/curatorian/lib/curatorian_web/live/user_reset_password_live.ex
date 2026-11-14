defmodule CuratorianWeb.UserResetPasswordLive do
  @moduledoc """
  Password reset page — reached from the emailed token link.

  Deliberately does NOT log the user in after reset: a leaked reset token
  must not yield an account session. Resetting also confirms an unconfirmed
  account (voile's reset flow handles that).
  """

  use CuratorianWeb, :live_view

  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex justify-center px-4 py-6">
        <div class="w-full max-w-lg">
          <div class="card bg-base-100 shadow-xl border border-base-300 overflow-hidden">
            <div class="h-1.5 w-full bg-primary"></div>

            <div class="card-body gap-6 p-8 lg:p-10">
              <div class="flex flex-col items-center text-center gap-3">
                <div class="w-16 h-16 rounded-full bg-primary/15 flex items-center justify-center">
                  <.icon name="hero-lock-closed" class="size-7 text-primary" />
                </div>
                <div>
                  <h1 class="text-2xl font-semibold text-base-content mb-1">
                    Atur ulang kata sandi
                  </h1>
                  <p class="text-sm text-base-content/60 max-w-xs mx-auto">
                    Buat kata sandi baru di bawah. Gunakan yang panjang dan unik.
                  </p>
                </div>
              </div>

              <.form
                for={@form}
                id="reset-password-form"
                phx-submit="reset_password"
                phx-change="validate"
              >
                <div class="space-y-4">
                  <.input
                    field={@form[:password]}
                    type="password"
                    label="Kata sandi baru"
                    placeholder="Minimal 12 karakter"
                    required
                    autocomplete="new-password"
                  />
                  <.input
                    field={@form[:password_confirmation]}
                    type="password"
                    label="Konfirmasi kata sandi baru"
                    required
                    autocomplete="new-password"
                  />

                  <.button
                    type="submit"
                    class="btn btn-primary w-full"
                    phx-disable-with="Menyimpan…"
                  >
                    Simpan kata sandi baru
                  </.button>
                </div>
              </.form>

              <div class="text-center text-sm text-base-content/60">
                <.link navigate={~p"/login"} class="link link-primary">
                  Kembali ke halaman masuk
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{user: user} -> Accounts.change_user_password(user, %{})
        _ -> %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Kata sandi berhasil diatur ulang. Silakan masuk.")
         |> redirect(to: ~p"/login")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, "Tautan atur ulang tidak valid atau sudah kedaluwarsa.")
      |> redirect(to: ~p"/login")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: :user))
  end
end
