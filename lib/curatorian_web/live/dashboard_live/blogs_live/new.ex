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

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:blog, %Blog{})
      |> assign(:user_id, user_id)
      |> assign(:uploaded_files, [])
      |> allow_upload(:thumbnail,
        accept: ~w(.jpg .jpeg .png),
        max_files: 1,
        max_file_size: 3_000_000,
        auto_upload: true
      )

    {:ok, socket}
  end
end
