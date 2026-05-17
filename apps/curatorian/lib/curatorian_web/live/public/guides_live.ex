defmodule CuratorianWeb.Public.GuidesLive do
  @moduledoc "Public guide library listing."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @sort_options [{"Terbaru", "newest"}, {"Terpopuler", "popular"}]

  @impl true
  def mount(_params, _session, socket) do
    tags = Public.list_popular_guide_tags(24)
    categories = Public.list_guide_categories()
    series = Public.list_guide_series()

    {:ok,
     socket
     |> assign(:page_title, "Panduan")
     |> assign(:sort_options, @sort_options)
     |> assign(:popular_tags, tags)
     |> assign(:categories, categories)
     |> assign(:guides, [])
     |> assign(:series, series)
     |> assign(:selected_series_id, nil)
     |> assign(:selected_series_title, nil)
     |> assign(:selected_series_guides, [])
     |> assign(:selected_series_open?, true)
     |> assign(:active_tab, "all")
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
    active_tab = Map.get(params, "tab", "all")
    selected_series_id = Map.get(params, "series")

    guides = Public.list_guides(search: search, category: category, tag: tag, sort: sort, page: page)
    total = Public.count_guides(search: search, category: category, tag: tag)
    total_pages = max(1, ceil(total / Public.page_size()))
    series = socket.assigns.series || Public.list_guide_series()

    selected_series_guides =
      if active_tab == "series" && selected_series_id do
        Public.list_published_series_guides(selected_series_id)
      else
        []
      end

    selected_series_title =
      if selected_series_id do
        Enum.find(series, &(&1.id == selected_series_id))
        |> then(fn series -> if series, do: series.title end)
      end

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:active_category, category)
     |> assign(:active_tag, tag)
     |> assign(:sort, sort)
     |> assign(:page, page)
     |> assign(:total_count, total)
     |> assign(:total_pages, total_pages)
     |> assign(:active_tab, active_tab)
     |> assign(:selected_series_id, selected_series_id)
     |> assign(:selected_series_title, selected_series_title)
     |> assign(:selected_series_guides, selected_series_guides)
     |> assign(:selected_series_open?, true)
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

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    params = build_params(socket.assigns.search, socket.assigns.active_category, socket.assigns.active_tag, socket.assigns.sort, socket.assigns.page, tab, nil)
    {:noreply, push_patch(socket, to: ~p"/guides?#{params}")}
  end

  def handle_event("select_series", %{"series-id" => series_id}, socket) do
    params = build_params(socket.assigns.search, socket.assigns.active_category, socket.assigns.active_tag, socket.assigns.sort, socket.assigns.page, "series", series_id)
    {:noreply, push_patch(socket, to: ~p"/guides?#{params}")}
  end

  def handle_event("toggle_series_list", _, socket) do
    {:noreply, assign(socket, :selected_series_open?, !socket.assigns.selected_series_open?)}
  end

  defp build_params(q, category, tag, sort, page, tab \\ "all", selected_series_id \\ nil) do
    %{}
    |> then(fn p -> if q && q != "", do: Map.put(p, "q", q), else: p end)
    |> then(fn p -> if category && category != "", do: Map.put(p, "category", category), else: p end)
    |> then(fn p -> if tag && tag != "", do: Map.put(p, "tag", tag), else: p end)
    |> then(fn p -> if sort != "newest", do: Map.put(p, "sort", sort), else: p end)
    |> then(fn p -> if page > 1, do: Map.put(p, "page", page), else: p end)
    |> then(fn p -> if tab != "all", do: Map.put(p, "tab", tab), else: p end)
    |> then(fn p -> if tab == "series" && selected_series_id, do: Map.put(p, "series", selected_series_id), else: p end)
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
        <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between mb-8">
          <div class="space-y-3">
            <p class="text-xs uppercase tracking-[0.3em] text-base-content/50">Mode tampilan</p>
            <div class="inline-flex rounded-full bg-base-200 p-1 shadow-sm ring-1 ring-base-200/70 dark:bg-base-300/70 dark:ring-base-300/50">
              <button
                phx-click="set_tab"
                phx-value-tab="all"
                class={[
                  "px-4 py-2 text-sm font-semibold rounded-full transition",
                  @active_tab == "all" && "bg-base-100 text-base-content shadow-sm dark:bg-base-200",
                  @active_tab != "all" && "text-base-content/70 hover:text-base-content dark:text-base-content/60"
                ]}
              >
                Semua Panduan
              </button>
              <button
                phx-click="set_tab"
                phx-value-tab="series"
                class={[
                  "px-4 py-2 text-sm font-semibold rounded-full transition",
                  @active_tab == "series" && "bg-base-100 text-base-content shadow-sm dark:bg-base-200",
                  @active_tab != "series" && "text-base-content/70 hover:text-base-content dark:text-base-content/60"
                ]}
              >
                Serial
              </button>
            </div>
          </div>

          <p class="text-sm text-base-content/60 max-w-xl">
            {if @active_tab == "series",
              do: "Jelajahi serial panduan dan buka setiap bagian berurutan.",
              else: "Temukan panduan tunggal atau gunakan filter untuk menemukan topik yang tepat."
            }
          </p>
        </div>

        <%= if @active_tab == "all" do %>
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
                    phx-value-category={cat.category}
                    class={[
                      "text-left text-sm px-3 py-1.5 rounded-lg transition-colors capitalize",
                      @active_category == cat.category &&
                        "bg-primary/10 text-primary font-medium",
                      @active_category != cat.category &&
                        "text-base-content/70 hover:bg-base-200"
                    ]}
                  >
                    <div class="flex items-center justify-between gap-3 w-full">
                      <span>{category_label(cat.category)}</span>
                      <span class="text-xs text-base-content/40">{cat.count}</span>
                    </div>
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
                      <%= if guide.series do %>
                        <div class="flex items-center gap-1 text-xs font-medium text-primary/80">
                          <.icon name="hero-book-open" class="w-3.5 h-3.5 shrink-0" />
                          <span class="truncate">{guide.series.title}</span>
                          <%= if guide.series_position do %>
                            <span class="shrink-0 text-base-content/40">· Part {guide.series_position}</span>
                          <% end %>
                        </div>
                      <% end %>
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
        <% else %>
          <div class="grid gap-8 lg:grid-cols-[280px_minmax(0,1fr)]">
            <aside class="space-y-4">
              <div class="rounded-[2rem] border border-base-200 bg-base-100 p-5 shadow-sm">
                <div class="flex flex-col gap-4 mb-4">
                  <div class="flex items-center justify-between gap-2">
                    <p class="text-xs uppercase tracking-[0.3em] text-base-content/50">Serial</p>
                    <span class="badge badge-sm bg-base-200 text-base-content">
                      {length(@series)} serial
                    </span>
                  </div>
                  <h5 class="text-lg font-semibold">Pilih serial</h5>
                </div>

                <div class="space-y-3">
                  <button
                    :for={series <- @series}
                    phx-click="select_series"
                    phx-value-series-id={series.id}
                    class={[
                      "w-full text-left rounded-xl border px-4 py-3 transition",
                      @selected_series_id == series.id && "border-primary bg-primary/10 text-primary",
                      @selected_series_id != series.id && "border-base-200 bg-base-100 text-base-content hover:border-primary/30 hover:bg-base-200"
                    ]}
                  >
                    <div class="flex items-center justify-between gap-3">
                      <span class="font-semibold truncate">{series.title}</span>
                      <span class="text-xs text-base-content/50">{series.guide_count}</span>
                    </div>
                    <p class="mt-1 text-xs text-base-content/60">Bagian berurutan</p>
                  </button>
                </div>
              </div>
            </aside>

            <section class="space-y-6">
              <div class="rounded-[2rem] border border-base-200 bg-gradient-to-br from-primary/10 via-base-100 to-secondary/10 p-6 shadow-sm">
                <div class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                  <div>
                    <p class="text-xs uppercase tracking-[0.3em] text-base-content/50">Serial Unggulan</p>
                    <h2 class="text-2xl font-semibold">
                      <%= if @selected_series_title do %>
                        {@selected_series_title}
                      <% else %>
                        Serial panduan populer
                      <% end %>
                    </h2>
                  </div>

                  <div class="flex items-center gap-2">
                    <%= if @selected_series_guides != [] do %>
                      <span class="badge badge-lg bg-primary/10 text-primary">
                        {length(@selected_series_guides)} bagian
                      </span>
                    <% end %>
                    <button
                      phx-click="toggle_series_list"
                      class="btn btn-sm btn-outline"
                    >
                      <%= if @selected_series_open? do %>
                        Sembunyikan daftar
                      <% else %>
                        Tampilkan daftar
                      <% end %>
                    </button>
                  </div>
                </div>
                <p class="text-sm text-base-content/60">
                  <%= if @selected_series_title do %>
                    Jelajahi langkah demi langkah dalam serial ini, atau buka ulang daftar jika ingin pindah serial.
                  <% else %>
                    Mulai pembelajaran berurutan dengan memilih serial di panel kiri.
                  <% end %>
                </p>

                <%= if @selected_series_title && @selected_series_guides != [] do %>
                  <div class="mt-4 rounded-3xl border border-primary/20 bg-primary/5 p-4 text-sm text-base-content/80">
                    <p class="font-medium text-base-content">
                      Mulai dari bagian pertama: <span class="font-semibold">{List.first(@selected_series_guides).title}</span>
                    </p>
                  </div>
                <% end %>
              </div>

              <div class="grid gap-4">
                <%= if @selected_series_guides == [] do %>
                  <div class="rounded-[2rem] border border-dashed border-base-200 bg-base-100 p-12 text-center text-base-content/60">
                    Tidak ada serial dipilih. <span class="font-semibold text-base-content">Pilih serial</span> dari daftar di kiri.
                  </div>
                <% else %>
                  <%= if @selected_series_open? do %>
                    <div class="grid gap-4">
                      <%= for guide <- @selected_series_guides do %>
                        <.link
                          navigate={~p"/guides/#{guide.slug}"}
                          class="group block rounded-[2rem] border border-base-200 bg-base-100 p-5 transition hover:border-primary/30 hover:shadow-lg"
                        >
                          <div class="flex items-center gap-3 text-xs uppercase tracking-[0.3em] text-base-content/50">
                            <span class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-primary/10 text-primary font-semibold">
                              {guide.series_position}
                            </span>
                            <span class="font-semibold">Bagian #{guide.series_position}</span>
                          </div>
                          <h3 class="mt-3 text-lg font-semibold text-base-content group-hover:text-primary transition-colors">
                            {guide.title}
                          </h3>
                          <p class="mt-2 text-sm text-base-content/60">
                            {guide.description || "Akses untuk serial ke #{guide.series_position}"}
                          </p>
                        </.link>
                      <% end %>
                    </div>
                  <% else %>
                    <div class="rounded-[2rem] border border-base-200 bg-base-100 p-12 text-center text-base-content/60">
                      Daftar serial disembunyikan. Klik tombol di atas untuk menampilkannya kembali.
                    </div>
                  <% end %>
                <% end %>
              </div>
            </section>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
