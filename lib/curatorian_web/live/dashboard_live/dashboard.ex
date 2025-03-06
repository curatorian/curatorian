defmodule CuratorianWeb.DashboardLive do
  use CuratorianWeb, :live_view_dashboard

  import CuratorianWeb.DashboardComponents

  alias Curatorian.Blogs

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
          <.stat_cards icon="hero-home-solid" number={@count_blogs} title="Your Total Blogpost" />
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
    count_blogs = Blogs.count_blogs_by_user(user.id)

    socket =
      socket
      |> assign(:user, user)
      |> assign(:count_blogs, count_blogs)

    {:ok, socket}
  end
end
