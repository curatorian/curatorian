defmodule CuratorianWeb.DashboardLive do
  use CuratorianWeb, :live_view_dashboard

  import CuratorianWeb.DashboardComponents

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
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 my-10">
          <.stat_cards
            icon="hero-home-solid"
            number={12_312_312_314}
            title="Average Treatment Cost For Them"
          />
          <.stat_cards
            icon="hero-computer-desktop-solid"
            number={14_123_124}
            title="Average Hardware Cost For IT"
          />
          <.stat_cards
            icon="hero-cube-solid"
            number={444_123}
            title="Average Treatment Cost For Them"
          />
        </div>
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
