defmodule CuratorianWeb.DashboardLive.BlogsLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Blogs
  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <.header>
      <div class="flex items-center justify-between">
        <div>
          Blog {@blog.slug}
        </div>
        
        <div>
          <.link href={~p"/dashboard/blog/#{@blog.slug}/edit"}>
            <.button>Edit</.button>
          </.link>
        </div>
      </div>
    </.header>

    <.back navigate="/dashboard/blog">Kembali</.back>

    <article class="my-10">
      <h2>{@blog.title}</h2>
      
      <p class="my-5">By: {@user_profile.fullname}</p>
      
      <div>
        <img src={@blog.image_url} />
        <p>{raw(@blog.content)}</p>
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
