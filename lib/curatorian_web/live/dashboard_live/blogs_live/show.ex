defmodule CuratorianWeb.DashboardLive.BlogsLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Blogs
  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <.header>
      Blog {@blog.slug}
    </.header>

    <.back navigate="/dashboard/blog">Kembali</.back>

    <article>
      <h1>{@blog.title}</h1>
      
      <p>By: {@user_profile.fullname}</p>
      
      <div>
        <p>{@blog.content}</p>
      </div>
    </article>
    """
  end

  def mount(%{"slug" => slug}, _session, socket) do
    blog = Blogs.get_blog_by_slug(slug)
    user_profile = Accounts.get_user_profile_by_user_id(blog.user_id)

    socket =
      socket
      |> assign(:blog, blog)
      |> assign(:user_profile, user_profile)

    {:ok, socket}
  end
end
