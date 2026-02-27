defmodule CuratorianWeb.UserConfirmationLive do
  @moduledoc """
  Handles the email confirmation token link that was sent to the user.
  """

  use CuratorianWeb, :live_view

  alias Curatorian.Accounts

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen flex items-center justify-center py-16 px-4">
        <div class="w-full max-w-md">
          <div class="card bg-base-100 shadow-xl border border-base-300">
            <div class="card-body gap-6">
              <%!-- Header --%>
              <div class="text-center">
                <div class="inline-flex items-center justify-center w-16 h-16 bg-primary/10 rounded-full mb-4">
                  <.icon name="hero-envelope-open" class="w-8 h-8 text-primary" />
                </div>
                <h1 class="text-2xl font-bold mb-1">Confirm your account</h1>
                <p class="text-base-content/60 text-sm">
                  Verify your email address to activate your account
                </p>
              </div>

              <%= if @user do %>
                <div class="bg-base-200 rounded-xl p-4 text-center">
                  <p class="text-xs text-base-content/50 mb-1">Confirming account for</p>
                  <p class="font-semibold">{@user.email}</p>
                </div>

                <.form for={@form} id="confirmation_form" phx-submit="confirm_account">
                  <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
                  <.button
                    type="submit"
                    phx-disable-with="Confirming…"
                    class="btn btn-primary w-full"
                  >
                    <.icon name="hero-check-badge" class="w-5 h-5 mr-2 inline-block" />
                    Confirm my account
                  </.button>
                </.form>
              <% else %>
                <div class="alert alert-error">
                  <.icon name="hero-exclamation-triangle" class="w-5 h-5" />
                  <span>
                    This confirmation link is invalid or has expired. Please request a new one.
                  </span>
                </div>

                <.link
                  navigate={~p"/users/pending_confirmation"}
                  class="btn btn-outline btn-primary w-full"
                >
                  Request new confirmation email
                </.link>
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
