defmodule CuratorianWeb.DashboardLive.BlogsLive.Index do
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

    <section class="grid grid-cols-3 gap-4">
      <%= for blog <- @blogs do %>
        <div class="bg-violet-100 p-4 rounded-xl flex flex-col items-center justify-between text-center gap-4">
          <h5>{blog.title}</h5>
          
          <p class="text-xs">{blog.summary}</p>
          
          <.link href={~p"/dashboard/blog/#{blog.slug}"}>
            <.button>View</.button>
          </.link>
        </div>
      <% end %>
    </section>
    """
  end

  def mount(_params, _session, socket) do
    blogs = Blogs.list_blogs_by_user(socket.assigns.current_user.id)

    socket =
      socket
      |> assign(:blogs, blogs)

    {:ok, socket}
  end

  def handle_info({CuratorianWeb.DashboardLive.BlogsLive.BlogForm, {:saved, blog}}, socket) do
    {:noreply, stream_insert(socket, :blogs, blog)}
  end
end
