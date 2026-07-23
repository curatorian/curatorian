defmodule CuratorianWeb.UserPendingConfirmationLive do
  @moduledoc """
  Shown immediately after registration to tell the user to check their inbox.
  Also lets them re-send the confirmation email if needed.
  """

  use CuratorianWeb, :live_view

  require Logger

  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex justify-center px-4 py-6">
        <div class="w-full max-w-lg">
          <div class="card bg-base-100 shadow-xl border border-base-300 overflow-hidden">
            <%!-- Top accent strip --%>
            <div class="h-1.5 w-full bg-warning"></div>

            <div class="card-body gap-6 p-8 lg:p-10">
              <%!-- Header --%>
              <div class="flex flex-col items-center text-center gap-3">
                <div class="w-16 h-16 rounded-full bg-warning/15 flex items-center justify-center motion-safe:animate-pulse">
                  <.icon name="hero-envelope" class="size-7 text-warning" />
                </div>
                <div>
                  <h1 class="text-2xl font-semibold text-base-content mb-1">Cek kotak masuk Anda</h1>
                  <p class="text-sm text-base-content/60 max-w-xs mx-auto leading-relaxed">
                    Kami telah mengirimkan tautan konfirmasi untuk memverifikasi akun Anda.
                  </p>
                </div>
              </div>

              <%= if @email do %>
                <%!-- Email display --%>
                <div class="bg-base-200 rounded-box px-5 py-4 flex items-center gap-3">
                  <.icon name="hero-at-symbol" class="size-4 text-base-content/40 shrink-0" />
                  <div class="min-w-0">
                    <p class="text-xs text-base-content/50 mb-0.5">Konfirmasi dikirim ke</p>
                    <p class="font-medium text-sm text-base-content truncate">{@email}</p>
                  </div>
                </div>

                <%!-- Steps --%>
                <ol class="space-y-3">
                  <li class="flex items-start gap-3 text-sm text-base-content/70">
                    <span class="flex-shrink-0 w-5 h-5 rounded-full bg-base-300 text-base-content/60 text-xs flex items-center justify-center font-medium mt-0.5">
                      1
                    </span>
                    <span>Buka email dari Curatorian di kotak masuk Anda (atau folder spam).</span>
                  </li>
                  <li class="flex items-start gap-3 text-sm text-base-content/70">
                    <span class="flex-shrink-0 w-5 h-5 rounded-full bg-base-300 text-base-content/60 text-xs flex items-center justify-center font-medium mt-0.5">
                      2
                    </span>
                    <span>Klik tautan konfirmasi untuk mengaktifkan akun Anda.</span>
                  </li>
                  <li class="flex items-start gap-3 text-sm text-base-content/70">
                    <span class="flex-shrink-0 w-5 h-5 rounded-full bg-base-300 text-base-content/60 text-xs flex items-center justify-center font-medium mt-0.5">
                      3
                    </span>
                    <span>Masuk dan mulai gunakan Curatorian.</span>
                  </li>
                </ol>

                <.form for={%{}} id="resend_form" phx-submit="resend_confirmation">
                  <input type="hidden" name="email" value={@email} />
                  <.button
                    type="submit"
                    phx-disable-with="Mengirim…"
                    class="btn btn-outline btn-primary w-full gap-2 motion-safe:transition-all motion-safe:duration-200"
                  >
                    <.icon name="hero-paper-airplane" class="size-4" /> Kirim ulang email konfirmasi
                  </.button>
                </.form>
              <% else %>
                <div class="alert alert-warning">
                  <.icon name="hero-exclamation-triangle" class="size-5 shrink-0" />
                  <span class="text-sm">
                    Alamat email tidak ditemukan.
                    <.link
                      navigate={~p"/register"}
                      class="font-medium underline underline-offset-2 ml-1"
                    >
                      Daftar
                    </.link>
                    untuk membuat akun.
                  </span>
                </div>
              <% end %>

              <div class="divider text-base-content/30 text-xs">Sudah dikonfirmasi?</div>

              <.link
                navigate={~p"/login"}
                class="btn btn-ghost btn-sm w-full text-base-content/60 hover:text-base-content motion-safe:transition-all motion-safe:duration-200"
              >
                <.icon name="hero-arrow-left" class="size-4" /> Kembali ke halaman masuk
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(params, _session, socket) do
    if socket.assigns.current_scope && socket.assigns.current_scope.user do
      {:ok, push_navigate(socket, to: "/")}
    else
      {:ok, assign(socket, :email, params["email"])}
    end
  end

  def handle_event("resend_confirmation", %{"email" => email}, socket) do
    case Accounts.get_user_by_email(email) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "No account found with that email address.")
         |> push_navigate(to: ~p"/register")}

      user ->
        if user.confirmed_at do
          {:noreply,
           socket
           |> put_flash(:info, "This account is already confirmed. You can sign in now.")
           |> push_navigate(to: ~p"/login")}
        else
          case Accounts.deliver_user_confirmation_instructions(
                 user,
                 &url(~p"/users/confirm/#{&1}")
               ) do
            {:ok, _} ->
              {:noreply, put_flash(socket, :info, "Confirmation email sent! Check your inbox.")}

            {:error, reason} ->
              Logger.error("Failed to resend confirmation email: #{inspect(reason)}")

              {:noreply,
               put_flash(
                 socket,
                 :warning,
                 "Could not send confirmation email right now. Please try again in a few minutes."
               )}
          end
        end
    end
  end
end
