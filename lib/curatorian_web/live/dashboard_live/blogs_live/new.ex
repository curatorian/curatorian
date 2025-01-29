defmodule CuratorianWeb.DashboardLive.BlogsLive.New do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Blogs
  alias Curatorian.Blogs.Blog

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
      title="New Blog"
      navigate={~p"/dashboard/blog"}
      action={:new}
    />
    <.back navigate="/dashboard/blog">Kembali</.back>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Blogs.change_blog(%Blog{})
    user_id = socket.assigns.current_user.id

    dbg(user_id)

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:blog, %Blog{})
      |> assign(:user_id, user_id)

    {:ok, socket}
  end
end
