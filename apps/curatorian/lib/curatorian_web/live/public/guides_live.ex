defmodule CuratorianWeb.Public.GuidesLive do
  @moduledoc "Public guide library listing."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @sort_options [{"Terbaru", "newest"}, {"Terpopuler", "popular"}]

  @impl true
  def mount(_params, _session, socket) do
    tags = Public.list_popular_guide_tags(24)
    categories = Public.list_guide_categories()

    {:ok,
     socket
     |> assign(:page_title, "Panduan")
     |> assign(:sort_options, @sort_options)
     |> assign(:popular_tags, tags)
     |> assign(:categories, categories)
     |> assign(:guides, [])
     |> assign(:total_count, 0)
     |> assign(:total_pages, 1)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    search = Map.get(params, "q", "")
    category = Map.get(params, "category", nil)
    tag = Map.get(params, "tag", nil)
    sort = Map.get(params, "sort", "newest")
    page = String.to_integer(Map.get(params, "page", "1"))

    guides = Public.list_guides(search: search, category: category, tag: tag, sort: sort, page: page)
    total = Public.count_guides(search: search, category: category, tag: tag)
    total_pages = max(1, ceil(total / Public.page_size()))

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:active_category, category)
     |> assign(:active_tag, tag)
     |> assign(:sort, sort)
     |> assign(:page, page)
     |> assign(:total_count, total)
     |> assign(:total_pages, total_pages)
     |> assign(:guides, guides)}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    params = build_params(q, socket.assigns.active_category, socket.assigns.active_tag, socket.assigns.sort, 1)
    {:noreply, push_patch(socket, to: ~p"/guides?#{params}")}
  end

  @impl true
  def handle_event("filter_category", %{"category" => cat}, socket) do
    category = if cat == "", do: nil, else: cat
    params = build_params(socket.assigns.search, category, socket.assigns.active_tag, socket.assigns.sort, 1)
    {:noreply, push_patch(socket, to: ~p"/guides?#{params}")}
  end

  @impl true
  def handle_event("filter_tag", %{"tag" => tag}, socket) do
    new_tag = if socket.assigns.active_tag == tag, do: nil, else: tag
    params = build_params(socket.assigns.search, socket.assigns.active_category, new_tag, socket.assigns.sort, 1)
    {:noreply, push_patch(socket, to: ~p"/guides?#{params}")}
  end

  @impl true
  def handle_event("sort", %{"sort" => sort}, socket) do
    params = build_params(socket.assigns.search, socket.assigns.active_category, socket.assigns.active_tag, sort, 1)
    {:noreply, push_patch(socket, to: ~p"/guides?#{params}")}
  end

  @impl true
  def handle_event("prev_page", _, socket) do
    page = max(1, socket.assigns.page - 1)
    params = build_params(socket.assigns.search, socket.assigns.active_category, socket.assigns.active_tag, socket.assigns.sort, page)
    {:noreply, push_patch(socket, to: ~p"/guides?#{params}")}
  end

  @impl true
  def handle_event("next_page", _, socket) do
    page = min(socket.assigns.total_pages, socket.assigns.page + 1)
    params = build_params(socket.assigns.search, socket.assigns.active_category, socket.assigns.active_tag, socket.assigns.sort, page)
    {:noreply, push_patch(socket, to: ~p"/guides?#{params}")}
  end

  defp build_params(q, category, tag, sort, page) do
    %{}
    |> then(fn p -> if q && q != "", do: Map.put(p, "q", q), else: p end)
    |> then(fn p -> if category && category != "", do: Map.put(p, "category", category), else: p end)
    |> then(fn p -> if tag && tag != "", do: Map.put(p, "tag", tag), else: p end)
    |> then(fn p -> if sort != "newest", do: Map.put(p, "sort", sort), else: p end)
    |> then(fn p -> if page > 1, do: Map.put(p, "page", page), else: p end)
  end

  defp category_label("getting_started"), do: "Getting Started"
  defp category_label("features"), do: "Features"
  defp category_label("integration"), do: "Integration"
  defp category_label("api"), do: "API"
  defp category_label("faq"), do: "FAQ"
  defp category_label(c), do: c |> String.replace("_", " ") |> String.capitalize()

  defp difficulty_badge(:beginner), do: {"bg-success/15 text-success", "Beginner"}
  defp difficulty_badge("beginner"), do: {"bg-success/15 text-success", "Beginner"}
  defp difficulty_badge(:intermediate), do: {"bg-warning/15 text-warning-content", "Intermediate"}
  defp difficulty_badge("intermediate"), do: {"bg-warning/15 text-warning-content", "Intermediate"}
  defp difficulty_badge(:advanced), do: {"bg-error/15 text-error", "Advanced"}
  defp difficulty_badge("advanced"), do: {"bg-error/15 text-error", "Advanced"}
  defp difficulty_badge(_), do: {"bg-base-200 text-base-content/50", ""}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <%!-- Hero section --%>
      <div class="bg-gradient-to-br from-primary/10 via-base-100 to-secondary/10 border-b border-base-200">
        <div class="max-w-5xl mx-auto px-4 py-12 text-center">
          <h1 class="text-4xl font-bold tracking-tight mb-3">Panduan</h1>
          <p class="text-base-content/60 text-lg max-w-xl mx-auto">
            Dokumentasi lengkap untuk membantu Anda memaksimalkan platform.
          </p>

          <%!-- Search --%>
          <form phx-submit="search" class="mt-6 flex gap-2 max-w-md mx-auto">
            <input
              type="text"
              name="q"
              value={@search}
              placeholder="Cari panduan..."
              class="input input-bordered flex-1"
            />
            <button type="submit" class="btn btn-primary">
              <.icon name="hero-magnifying-glass" class="w-5 h-5" />
            </button>
          </form>
        </div>
      </div>

      <div class="max-w-5xl mx-auto px-4 py-8">
        <div class="flex flex-col lg:flex-row gap-8">
          <%!-- Sidebar filters --%>
          <aside class="lg:w-56 shrink-0">
            <%!-- Category filter --%>
            <div class="mb-6">
              <h3 class="text-xs font-semibold uppercase tracking-wider text-base-content/50 mb-3">
                Kategori
              </h3>
              <div class="flex flex-col gap-1">
                <button
                  phx-click="filter_category"
                  phx-value-category=""
                  class={[
                    "text-left text-sm px-3 py-1.5 rounded-lg transition-colors",
                    !@active_category &&
                      "bg-primary/10 text-primary font-medium",
                    @active_category &&
                      "text-base-content/70 hover:bg-base-200"
                  ]}
                >
                  Semua Kategori
                </button>
                <button
                  :for={cat <- @categories}
                  phx-click="filter_category"
                  phx-value-category={cat}
                  class={[
                    "text-left text-sm px-3 py-1.5 rounded-lg transition-colors capitalize",
                    @active_category == cat &&
                      "bg-primary/10 text-primary font-medium",
                    @active_category != cat &&
                      "text-base-content/70 hover:bg-base-200"
                  ]}
                >
                  {category_label(cat)}
                </button>
              </div>
            </div>

            <%!-- Popular tags --%>
            <%= if @popular_tags != [] do %>
              <div>
                <h3 class="text-xs font-semibold uppercase tracking-wider text-base-content/50 mb-3">
                  Tag Populer
                </h3>
                <div class="flex flex-wrap gap-1.5">
                  <button
                    :for={{tag, _count} <- @popular_tags}
                    phx-click="filter_tag"
                    phx-value-tag={tag}
                    class={[
                      "badge badge-sm cursor-pointer transition-colors",
                      @active_tag == tag && "badge-primary",
                      @active_tag != tag && "badge-ghost hover:badge-primary"
                    ]}
                  >
                    {tag}
                  </button>
                </div>
              </div>
            <% end %>
          </aside>

          <%!-- Main content --%>
          <div class="flex-1 min-w-0">
            <%!-- Sort & count bar --%>
            <div class="flex items-center justify-between mb-4">
              <p class="text-sm text-base-content/60">
                {@total_count} panduan ditemukan
              </p>
              <div class="flex items-center gap-2">
                <span class="text-xs text-base-content/40">Urutkan:</span>
                <button
                  :for={{label, value} <- @sort_options}
                  phx-click="sort"
                  phx-value-sort={value}
                  class={[
                    "btn btn-xs",
                    @sort == value && "btn-primary",
                    @sort != value && "btn-ghost"
                  ]}
                >
                  {label}
                </button>
              </div>
            </div>

            <%!-- Active filters pills --%>
            <%= if @active_tag || @active_category do %>
              <div class="flex flex-wrap gap-2 mb-4">
                <%= if @active_category do %>
                  <button
                    phx-click="filter_category"
                    phx-value-category=""
                    class="badge badge-primary gap-1 cursor-pointer"
                  >
                    {category_label(@active_category)}
                    <.icon name="hero-x-mark" class="w-3 h-3" />
                  </button>
                <% end %>
                <%= if @active_tag do %>
                  <button
                    phx-click="filter_tag"
                    phx-value-tag={@active_tag}
                    class="badge badge-secondary gap-1 cursor-pointer"
                  >
                    {@active_tag}
                    <.icon name="hero-x-mark" class="w-3 h-3" />
                  </button>
                <% end %>
              </div>
            <% end %>

            <%!-- Guide grid --%>
            <%= if @guides == [] do %>
              <div class="py-16 text-center text-base-content/40">
                <.icon name="hero-document-text" class="w-12 h-12 mx-auto mb-3 opacity-30" />
                <p>Tidak ada panduan ditemukan.</p>
              </div>
            <% else %>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <.link
                  :for={guide <- @guides}
                  navigate={~p"/guides/#{guide.slug}"}
                  class="card bg-base-100 border border-base-200 shadow-sm hover:shadow-md hover:border-primary/30 transition-all group"
                >
                  <%= if guide.cover_url do %>
                    <figure class="aspect-video overflow-hidden">
                      <img
                        src={guide.cover_url}
                        alt={guide.title}
                        class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                    </figure>
                  <% end %>
                  <div class="card-body p-4 gap-2">
                    <div class="flex flex-wrap gap-1.5">
                      <%= if guide.category do %>
                        <span class="badge badge-xs badge-outline capitalize">
                          {category_label(guide.category)}
                        </span>
                      <% end %>
                      <%= if guide.difficulty do %>
                        <% {badge_class, label} = difficulty_badge(guide.difficulty) %>
                        <%= if label != "" do %>
                          <span class={"badge badge-xs #{badge_class}"}>{label}</span>
                        <% end %>
                      <% end %>
                    </div>
                    <h3 class="font-semibold text-base leading-snug group-hover:text-primary transition-colors">
                      {guide.title}
                    </h3>
                    <%= if guide.description do %>
                      <p class="text-sm text-base-content/60 line-clamp-2">{guide.description}</p>
                    <% end %>
                    <div class="flex items-center gap-3 mt-1 text-xs text-base-content/40">
                      <%= if guide.estimated_read_minutes do %>
                        <span class="flex items-center gap-1">
                          <.icon name="hero-clock" class="w-3.5 h-3.5" />
                          {guide.estimated_read_minutes} mnt
                        </span>
                      <% end %>
                      <span class="flex items-center gap-1">
                        <.icon name="hero-eye" class="w-3.5 h-3.5" />
                        {guide.view_count}
                      </span>
                    </div>
                  </div>
                </.link>
              </div>

              <%!-- Pagination --%>
              <%= if @total_pages > 1 do %>
                <div class="flex justify-center items-center gap-3 mt-8">
                  <button
                    phx-click="prev_page"
                    disabled={@page <= 1}
                    class="btn btn-ghost btn-sm"
                  >
                    <.icon name="hero-chevron-left" class="w-4 h-4" />
                  </button>
                  <span class="text-sm text-base-content/60">
                    Halaman {@page} dari {@total_pages}
                  </span>
                  <button
                    phx-click="next_page"
                    disabled={@page >= @total_pages}
                    class="btn btn-ghost btn-sm"
                  >
                    <.icon name="hero-chevron-right" class="w-4 h-4" />
                  </button>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
