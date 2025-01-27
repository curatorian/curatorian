defmodule CuratorianWeb.DashboardLive.Blogs.BlogIndexLive do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Blogs

  def render(assigns) do
    ~H"""
    <.header>
      Listing Blogs
      <:actions>
        <.link href={~p"/dashboard/blog/new"}>
          <.button>New Blog</.button>
        </.link>
      </:actions>
    </.header>
    """
  end

  def mount(_params, _session, socket) do
    blogs = Blogs.list_blogs()

    socket =
      socket
      |> assign(:blogs, blogs)

    {:ok, socket}
  end
end
