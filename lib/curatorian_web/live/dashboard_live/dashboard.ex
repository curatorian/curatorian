defmodule CuratorianWeb.DashboardLive do
  use CuratorianWeb, :live_view_dashboard

  def render(assigns) do
    ~H"""
    <section class="container mx-auto">
      <.header class="text-center">
        Welcome to Curatorian Dashboard
      </.header>
      
      <div>
        <p>
          Halo, {@user.username}
        </p>
      </div>
    </section>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:user, user)

    {:ok, socket}
  end
end
