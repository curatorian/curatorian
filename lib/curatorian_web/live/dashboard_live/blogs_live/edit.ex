defmodule CuratorianWeb.DashboardLive.BlogsLive.Edit do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Blogs
  alias Curatorian.Blogs.Blog

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>
      Edit Blog
      <:subtitle>Use this form to manage blog records in your database.</:subtitle>
    </.header>

    <.live_component
      module={CuratorianWeb.DashboardLive.BlogsLive.BlogForm}
      id={@blog.id}
      blog={@blog}
      user_id={@user_id}
      title="New Blog"
      navigate={~p"/dashboard/blog"}
      action={:edit}
    />
    <.back navigate="/dashboard/blog">Kembali</.back>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"slug" => slug}, _session, socket) do
    blog = Blogs.get_blog_by_slug(slug)
    changeset = Blogs.change_blog(%Blog{})
    user_id = socket.assigns.current_user.id

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:blog, blog)
      |> assign(:user_id, user_id)

    {:ok, socket}
  end
end
