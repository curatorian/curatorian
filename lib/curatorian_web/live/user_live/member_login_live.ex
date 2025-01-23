defmodule CuratorianWeb.MemberLoginLive do
  use CuratorianWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mt-10 text-center">
      <.header>
        Masuk atau Daftar ke Curatorian
      </.header>
    </div>

    <div class="flex items-center justify-center mt-5">
      <.button phx-click="google_auth" class="bg-violet-100">
        Login with Google
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
