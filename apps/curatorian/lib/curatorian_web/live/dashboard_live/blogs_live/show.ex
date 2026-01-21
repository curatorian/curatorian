defmodule CuratorianWeb.DashboardLive.BlogsLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Blogs
  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <.modal id="confirm-delete">
      <div class="text-center">
        <.icon name="hero-exclamation-triangle" class="w-12 h-12 mx-auto text-red-600 mb-4" />
        <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">Delete Blog Post</h3>

        <p class="text-sm text-gray-500 dark:text-gray-400 mb-6">
          Are you sure you want to delete "<strong>{@blog.title}</strong>"? This action cannot be undone.
        </p>

        <div class="flex items-center justify-center gap-4">
          <.button phx-click={hide_modal("confirm-delete")} class="btn-secondary">Cancel</.button>
          <.button phx-click="delete-blog" phx-value-id={@blog.id} class="bg-red-600 hover:bg-red-700">
            <.icon name="hero-trash" class="w-4 h-4 mr-2" /> Delete
          </.button>
        </div>
      </div>
    </.modal>

    <div class="mb-6">
      <.link
        navigate="/dashboard/blog"
        class="inline-flex items-center text-sm text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-200"
      >
        <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back to Blogs
      </.link>
    </div>

    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg overflow-hidden">
      <%!-- Header Image --%>
      <%= if @blog.image_url do %>
        <div class="aspect-[21/9] overflow-hidden bg-gray-200 dark:bg-gray-700">
          <img src={@blog.image_url} alt={@blog.title} class="w-full h-full object-cover" />
        </div>
      <% end %>
      <%!-- Content --%>
      <article class="max-w-4xl mx-auto px-6 md:px-8 py-8">
        <%!-- Header with Actions --%>
        <div class="flex items-start justify-between mb-6 pb-6 border-b border-gray-200 dark:border-gray-700">
          <div class="flex-1">
            <div class="flex items-center gap-3 mb-4">
              <span class={[
                "px-3 py-1 text-xs font-semibold rounded-full",
                get_status_class(@blog.status)
              ]}>
                {String.capitalize(@blog.status || "draft")}
              </span>
              <span class="text-sm text-gray-500 dark:text-gray-400">
                {format_date(@blog.inserted_at)}
              </span>
            </div>

            <h1 class="text-3xl md:text-4xl font-bold text-gray-900 dark:text-gray-100 mb-4">
              {@blog.title}
            </h1>

            <%= if @blog.summary do %>
              <p class="text-lg text-gray-600 dark:text-gray-400">{@blog.summary}</p>
            <% end %>
          </div>

          <div class="flex items-center gap-2 ml-4">
            <.link href={~p"/dashboard/blog/#{@blog.slug}/edit"}>
              <.button class="btn-secondary">
                <.icon name="hero-pencil-square" class="w-4 h-4 md:mr-2" />
                <span class="hidden md:inline">Edit</span>
              </.button>
            </.link>
            <.button phx-click={show_modal("confirm-delete")} class="bg-red-600 hover:bg-red-700">
              <.icon name="hero-trash" class="w-4 h-4 md:mr-2" />
              <span class="hidden md:inline">Delete</span>
            </.button>
          </div>
        </div>
        <%!-- Author Card --%>
        <div class="flex items-center gap-4 mb-8 p-4 bg-gray-50 dark:bg-gray-900 rounded-lg">
          <%= if @user_profile.user_image do %>
            <img
              src={@user_profile.user_image}
              alt={@user_profile.fullname}
              class="w-12 h-12 rounded-full"
            />
          <% else %>
            <div class="w-12 h-12 rounded-full bg-gray-300 dark:bg-gray-600 flex items-center justify-center">
              <span class="text-lg font-semibold text-gray-700 dark:text-gray-200">
                {String.first(@user_profile.fullname || "?")}
              </span>
            </div>
          <% end %>

          <div>
            <p class="text-sm font-medium text-gray-900 dark:text-gray-100">
              {@user_profile.fullname}
            </p>

            <p class="text-xs text-gray-500 dark:text-gray-400">Author</p>
          </div>
        </div>
        <%!-- Blog Content --%>
        <div class="prose prose-lg dark:prose-invert max-w-none">{raw(@blog.content)}</div>
      </article>
    </div>
    """
  end

  def mount(%{"slug" => slug}, _session, socket) do
    blog = Blogs.get_blog_by_slug(slug)
    user_profile = Accounts.get_user_profile_by_user_id(blog.user_id)

    dbg(blog)

    socket =
      socket
      |> assign(:blog, blog)
      |> assign(:user_profile, user_profile)
      |> assign(:show_delete_modal, false)

    {:ok, socket}
  end

  def handle_event("delete-blog", %{"id" => id}, socket) do
    blog = Blogs.get_blog!(id)

    # Authorization: only the blog owner or privileged users can delete
    user_id = socket.assigns.current_scope.user.id
    user_profile = socket.assigns.current_scope.user.profile || socket.assigns.current_scope.user

    privileged_roles = ["manager", "admin", "coordinator"]

    authorized =
      (user_id && blog.user_id == user_id) or
        (user_profile && Map.get(user_profile, :user_role) in privileged_roles)

    if authorized do
      {:ok, _blog} = Blogs.delete_blog(blog)

      socket =
        socket
        |> put_flash(:info, "Blog deleted successfully.")
        |> redirect(to: "/dashboard/blog")

      {:noreply, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You are not authorized to delete this blog.")
        |> redirect(to: "/dashboard/blog")

      {:noreply, socket}
    end
  end

  defp get_status_class(status) do
    case status do
      "published" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      "draft" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
      "archived" -> "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200"
      _ -> "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
    end
  end

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y")
  end
end
