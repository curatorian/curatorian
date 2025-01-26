defmodule CuratorianWeb.DashboardLive do
  use CuratorianWeb, :live_view_dashboard

  def render(assigns) do
    ~H"""
    <section class="container mx-auto">
      <.header class="text-center">
        Welcome to Curatorian Dashboard
      </.header>
      
      <div>
        <img src={@user.profile.user_image} class="w-24 h-24 object-cover rounded-xl" />
        <p>
          Halo, {@user.username}
        </p>
      </div>
    </section>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    dbg(user)

    socket =
      socket
      |> assign(:user, user)

    {:ok, socket}
  end
end
