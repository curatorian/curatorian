defmodule CuratorianWeb.DashboardLive.Blogs.BlogNewLive do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Blogs
  alias Curatorian.Blogs.Blog

  def render(assigns) do
    ~H"""
    <.header>
      New Blog
      <:subtitle>Use this form to manage blog records in your database.</:subtitle>
    </.header>

    <.back navigate="/dashboard/blog">Kembali</.back>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Blogs.change_blog(%Blog{})

    socket =
      socket
      |> assign(:changeset, changeset)

    {:ok, socket}
  end
end
