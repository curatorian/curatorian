defmodule CuratorianWeb.DashboardLive do
  use CuratorianWeb, :live_view_dashboard

  import CuratorianWeb.DashboardComponents

  alias Curatorian.Blogs
  alias Voile.Schema.Accounts

  def render(assigns) do
    ~H"""
    <section class="w-full">
      <.header>Welcome to Curatorian Dashboard</.header>

      <div>
        <p>Halo, {@user.username}</p>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 my-10">
          <.stat_cards
            icon="hero-pencil-square-solid"
            number={@count_blogs}
            title="Your Total Blogpost"
          />
          <.stat_cards icon="hero-user-group-solid" number={@count_users} title="User Registered" />
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
    user = socket.assigns.current_scope.user
    count_blogs = Blogs.count_blogs_by_user(user.id)
    user_stats = Accounts.get_user_statistics()
    count_users = user_stats.total_users

    socket =
      socket
      |> assign(:user, user)
      |> assign(:count_blogs, count_blogs)
      |> assign(:count_users, count_users)

    {:ok, socket}
  end
end
