defmodule CuratorianWeb.UserConfirmationLive do
  @moduledoc """
  Handles the email confirmation token link that was sent to the user.
  """

  use CuratorianWeb, :live_view

  alias Curatorian.Accounts

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex justify-center px-4 py-6">
        <div class="w-full max-w-lg">
          <div class="card bg-base-100 shadow-xl border border-base-300 overflow-hidden">
            <%!-- Top accent strip — success green when user found, error otherwise --%>
            <div class={["h-1.5 w-full", if(@user, do: "bg-success", else: "bg-error")]}></div>

            <div class="card-body gap-6 p-8 lg:p-10">
              <%= if @user do %>
                <%!-- Success state — valid token --%>
                <div class="flex flex-col items-center text-center gap-3">
                  <div class="w-16 h-16 rounded-full bg-success/15 flex items-center justify-center">
                    <.icon name="hero-envelope-open" class="size-7 text-success" />
                  </div>
                  <div>
                    <h1 class="text-2xl font-semibold text-base-content mb-1">
                      Konfirmasi akun Anda
                    </h1>
                    <p class="text-sm text-base-content/60 max-w-xs mx-auto leading-relaxed">
                      Satu klik untuk memverifikasi alamat email dan mengaktifkan akun Anda.
                    </p>
                  </div>
                </div>

                <div class="bg-base-200 rounded-box px-5 py-4 flex items-center gap-3">
                  <.icon name="hero-at-symbol" class="size-4 text-base-content/40 shrink-0" />
                  <div class="min-w-0">
                    <p class="text-xs text-base-content/50 mb-0.5">Mengkonfirmasi akun untuk</p>
                    <p class="font-medium text-sm text-base-content truncate">{@user.email}</p>
                  </div>
                </div>

                <.form for={@form} id="confirmation_form" phx-submit="confirm_account">
                  <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
                  <.button
                    type="submit"
                    phx-disable-with="Mengkonfirmasi…"
                    class="btn btn-primary w-full gap-2 motion-safe:transition-all motion-safe:duration-200"
                  >
                    <.icon name="hero-check-badge" class="size-5" />
                    Konfirmasi akun saya
                  </.button>
                </.form>
              <% else %>
                <%!-- Error state — invalid or expired token --%>
                <div class="flex flex-col items-center text-center gap-3">
                  <div class="w-16 h-16 rounded-full bg-error/15 flex items-center justify-center">
                    <.icon name="hero-exclamation-triangle" class="size-7 text-error" />
                  </div>
                  <div>
                    <h1 class="text-2xl font-semibold text-base-content mb-1">Tautan kedaluwarsa</h1>
                    <p class="text-sm text-base-content/60 max-w-xs mx-auto leading-relaxed">
                      Tautan konfirmasi ini tidak valid atau sudah kedaluwarsa. Minta tautan baru di bawah.
                    </p>
                  </div>
                </div>

                <.link
                  navigate={~p"/users/pending_confirmation"}
                  class="btn btn-primary w-full gap-2 motion-safe:transition-all motion-safe:duration-200"
                >
                  <.icon name="hero-paper-airplane" class="size-4" />
                  Minta email konfirmasi baru
                </.link>
              <% end %>

              <div class="divider text-base-content/30 text-xs">Sudah dikonfirmasi?</div>

              <.link
                navigate={~p"/login"}
                class="btn btn-ghost btn-sm w-full text-base-content/60 hover:text-base-content motion-safe:transition-all motion-safe:duration-200"
              >
                <.icon name="hero-arrow-left" class="size-4" />
                Kembali ke halaman masuk
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    user = Accounts.get_user_by_confirmation_token(token)
    form = to_form(%{"token" => token}, as: "user")
    {:ok, assign(socket, form: form, user: user), temporary_assigns: [form: nil]}
  end

  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Email confirmed! You can now sign in.")
         |> redirect(to: ~p"/login")}

      :error ->
        case socket.assigns do
          %{current_scope: %{user: %{confirmed_at: confirmed_at}}}
          when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          _ ->
            {:noreply,
             socket
             |> put_flash(:error, "Confirmation link is invalid or has expired.")
             |> redirect(to: ~p"/")}
        end
    end
  end
end
