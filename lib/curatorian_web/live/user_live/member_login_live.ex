defmodule CuratorianWeb.MemberLoginLive do
  use CuratorianWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Register or Login with Google
      </.header>
    </div>

    <div>
      <.button phx-click="google_auth" class="w-full">
        Register or Login with Google
      </.button>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end

  def handle_event("google_auth", _params, socket) do
    {:noreply, socket |> redirect(to: "/auth/google")}
  end
end
