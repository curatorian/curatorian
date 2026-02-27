defmodule CuratorianWeb.UserPendingConfirmationLive do
  @moduledoc """
  Shown immediately after registration to tell the user to check their inbox.
  Also lets them re-send the confirmation email if needed.
  """

  use CuratorianWeb, :live_view

  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen flex items-center justify-center py-16 px-4">
        <div class="w-full max-w-md">
          <div class="card bg-base-100 shadow-xl border border-base-300">
            <div class="card-body gap-6">
              <%!-- Header --%>
              <div class="text-center">
                <div class="inline-flex items-center justify-center w-16 h-16 bg-warning/20 rounded-full mb-4">
                  <.icon name="hero-envelope" class="w-8 h-8 text-warning" />
                </div>
                <h1 class="text-2xl font-bold mb-1">Check your inbox</h1>
                <p class="text-base-content/60 text-sm">
                  We've sent a confirmation link to verify your account
                </p>
              </div>

              <%= if @email do %>
                <div class="bg-base-200 rounded-xl p-4 text-center">
                  <p class="text-xs text-base-content/50 mb-1">Confirmation sent to</p>
                  <p class="font-semibold text-sm">{@email}</p>
                </div>

                <div class="text-sm text-base-content/70 space-y-2">
                  <p>Click the link in your email to activate your account.</p>
                  <p>Didn't receive it? Check your spam folder or resend below.</p>
                </div>

                <.form for={%{}} id="resend_form" phx-submit="resend_confirmation">
                  <input type="hidden" name="email" value={@email} />
                  <.button
                    type="submit"
                    phx-disable-with="Sending…"
                    class="btn btn-outline btn-primary w-full"
                  >
                    Resend confirmation email
                  </.button>
                </.form>
              <% else %>
                <p class="text-center text-base-content/60 text-sm">
                  No email address found.
                  <.link navigate={~p"/register"} class="link link-primary">Register</.link>
                  to create an account.
                </p>
              <% end %>

              <div class="divider text-base-content/40 text-xs">Already confirmed?</div>

              <.link navigate={~p"/login"} class="btn btn-outline btn-primary w-full">
                Sign in
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
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

          {:noreply, put_flash(socket, :info, "Confirmation email sent! Check your inbox.")}
        end
    end
  end
end
