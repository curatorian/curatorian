defmodule CuratorianWeb.DashboardLive.BlogsLive.Index do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Blogs

  def render(assigns) do
    ~H"""
    <.header>
      My Blogs
      <:subtitle>Manage and publish your blog posts</:subtitle>

      <:actions>
        <.link href={~p"/dashboard/blog/new"}>
          <.button><.icon name="hero-plus" class="w-4 h-4 mr-2" /> Create New Blog</.button>
        </.link>
      </:actions>
    </.header>

    <%= if Enum.empty?(@blogs) do %>
      <div class="text-center py-16 bg-white dark:bg-gray-800 rounded-lg shadow mt-6">
        <.icon name="hero-document-text" class="w-16 h-16 mx-auto text-gray-400 mb-4" />
        <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">No blogs yet</h3>

        <p class="text-gray-500 dark:text-gray-400 mb-6">
          Get started by creating your first blog post
        </p>

        <.link href={~p"/dashboard/blog/new"}>
          <.button><.icon name="hero-plus" class="w-4 h-4 mr-2" /> Create Your First Blog</.button>
        </.link>
      </div>
    <% else %>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-6">
        <%= for blog <- @blogs do %>
          <article class="group bg-white dark:bg-gray-800 rounded-xl shadow-md overflow-hidden hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
            <div class="relative aspect-video overflow-hidden bg-gray-200 dark:bg-gray-700">
              <%= if blog.image_url do %>
                <img
                  src={blog.image_url}
                  alt={blog.title}
                  class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                />
              <% else %>
                <div class="w-full h-full flex items-center justify-center">
                  <.icon name="hero-photo" class="w-12 h-12 text-gray-400" />
                </div>
              <% end %>

              <div class="absolute top-3 right-3">
                <span class={[
                  "px-3 py-1 text-xs font-semibold rounded-full",
                  get_status_class(blog.status)
                ]}>
                  {String.capitalize(blog.status || "draft")}
                </span>
              </div>
            </div>

            <div class="p-5">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2 line-clamp-2 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                {blog.title}
              </h3>

              <%= if blog.summary do %>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 line-clamp-3">
                  {blog.summary}
                </p>
              <% end %>

              <div class="flex items-center justify-between pt-4 border-t border-gray-200 dark:border-gray-700">
                <div class="flex items-center gap-2 text-xs text-gray-500 dark:text-gray-400">
                  <.icon name="hero-clock" class="w-4 h-4" />
                  <time>{format_date(blog.inserted_at)}</time>
                </div>

                <.link
                  href={~p"/dashboard/blog/#{blog.slug}"}
                  class="text-sm font-medium text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 flex items-center gap-1"
                >
                  View <.icon name="hero-arrow-right" class="w-4 h-4" />
                </.link>
              </div>
            </div>
          </article>
        <% end %>
      </div>
    <% end %>
    <%!-- Pagination --%>
    <%= if not Enum.empty?(@blogs) and @total_pages > 1 do %>
      <div class="flex items-center justify-between mt-8 px-4 py-3 bg-white dark:bg-gray-800 rounded-lg shadow">
        <div class="text-sm text-gray-700 dark:text-gray-300">
          Showing <span class="font-medium">{length(@blogs)}</span>
          of <span class="font-medium">{@total_count}</span>
          blogs
        </div>

        <div class="flex items-center gap-2">
          <%= if @page > 1 do %>
            <.link
              patch={~p"/dashboard/blog?page=#{@page - 1}"}
              class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
            >
              Previous
            </.link>
          <% else %>
            <span class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm font-medium text-gray-400 bg-gray-100 dark:bg-gray-700 cursor-not-allowed">
              Previous
            </span>
          <% end %>

          <span class="text-sm text-gray-700 dark:text-gray-300">Page {@page} of {@total_pages}</span>
          <%= if @page < @total_pages do %>
            <.link
              patch={~p"/dashboard/blog?page=#{@page + 1}"}
              class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
            >
              Next
            </.link>
          <% else %>
            <span class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md text-sm font-medium text-gray-400 bg-gray-100 dark:bg-gray-700 cursor-not-allowed">
              Next
            </span>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Listing Blogs")
      |> assign(:page, 1)
      |> load_blogs()

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    page = String.to_integer(params["page"] || "1")

    socket =
      socket
      |> assign(:page, page)
      |> load_blogs()

    {:noreply, socket}
  end

  def handle_info({CuratorianWeb.DashboardLive.BlogsLive.BlogForm, {:saved, blog}}, socket) do
    {:noreply, stream_insert(socket, :blogs, blog)}
  end

  defp list_blogs(user_id, page) do
    Blogs.list_blogs_by_user_paginated(user_id, page)
  end

  defp load_blogs(socket) do
    user_id = socket.assigns.current_scope.user.id
    page = socket.assigns[:page] || 1

    result = list_blogs(user_id, page)

    socket
    |> assign(:blogs, result.blogs)
    |> assign(:page, result.page)
    |> assign(:per_page, result.per_page)
    |> assign(:total_count, result.total_count)
    |> assign(:total_pages, result.total_pages)
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
    Calendar.strftime(datetime, "%b %d, %Y")
  end
end
