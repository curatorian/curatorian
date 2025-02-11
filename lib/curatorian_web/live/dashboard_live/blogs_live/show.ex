defmodule CuratorianWeb.DashboardLive.BlogsLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Blogs
  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <.modal id="confirm-delete">
      <h2>Delete Blog</h2>

      <p class="my-5">Are you sure you want to delete this blog?</p>

      <div class="modal-footer">
        <.button phx-click="delete-blog" phx-value-id={@blog.id}>Delete</.button>
        <.button phx-click={hide_modal("confirm-delete")}>Cancel</.button>
      </div>
    </.modal>
    <.header>
      <div class="flex items-center justify-between">
        <div>
          Blog {@blog.slug}
        </div>

        <div>
          <.link href={~p"/dashboard/blog/#{@blog.slug}/edit"}>
            <.button>Edit</.button>
          </.link>
          <.button phx-click={show_modal("confirm-delete")}>Delete</.button>
        </div>
      </div>
    </.header>

    <.back navigate="/dashboard/blog">Kembali</.back>

    <article class="my-10">
      <h2>{@blog.title}</h2>

      <p class="my-5">By: {@user_profile.fullname}</p>

      <div>
        <img class="w-full my-5" src={@blog.image_url} />
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
      |> assign(:show_delete_modal, false)

    {:ok, socket}
  end

  def handle_event("delete-blog", %{"id" => id}, socket) do
    blog = Blogs.get_blog!(id)
    {:ok, _blog} = Blogs.delete_blog(blog)

    socket =
      socket
      |> put_flash(:info, "Blog deleted successfully.")
      |> redirect(to: "/dashboard/blog")

    {:noreply, socket}
  end
end
