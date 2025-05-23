defmodule CuratorianWeb.DashboardLive.BlogsLive.New do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Blogs
  alias Curatorian.Blogs.Blog

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>
      New Blog
      <:subtitle>Use this form to manage blog records in your database.</:subtitle>
    </.header>

    <.live_component
      module={CuratorianWeb.DashboardLive.BlogsLive.BlogForm}
      id={@blog.id || :new}
      blog={@blog}
      user_id={@user_id}
      categories={@categories}
      tags={@tags}
      title="New Blog"
      navigate={~p"/dashboard/blog"}
      action={:new}
    />
    <.back navigate="/dashboard/blog">Kembali</.back>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    changeset = Blogs.change_blog(%Blog{})
    user_id = socket.assigns.current_user.id
    categories = Blogs.list_categories()
    tags = Blogs.list_tags()

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:blog, %Blog{})
      |> assign(:categories, categories)
      |> assign(:tags, tags)
      |> assign(:user_id, user_id)

    {:ok, socket}
  end
end
