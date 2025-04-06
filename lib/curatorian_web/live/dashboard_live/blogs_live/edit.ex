defmodule CuratorianWeb.DashboardLive.BlogsLive.Edit do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Blogs
  alias Curatorian.Blogs.Blog

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-4">
      <.header>
        Edit Blog
        <:subtitle>Use this form to manage blog records in your database.</:subtitle>
      </.header>

      <div>
        <.link class="btn no-underline" navigate={"/#{@user_profile.username}/blog/#{@blog.slug}"}>
          Show Blog
        </.link>
      </div>
    </div>

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
    user_profile = socket.assigns.current_user
    user_id = socket.assigns.current_user.id

    if blog.user_id == user_id do
      changeset = Blogs.change_blog(%Blog{})

      socket =
        socket
        |> assign(:changeset, changeset)
        |> assign(:blog, blog)
        |> assign(:user_id, user_id)
        |> assign(:user_profile, user_profile)

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to edit this blog.")
       |> push_navigate(to: "/dashboard/blog")}
    end
  end
end
