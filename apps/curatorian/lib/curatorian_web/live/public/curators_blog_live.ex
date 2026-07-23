defmodule CuratorianWeb.Public.CuratorsBlogLive do
  @moduledoc "Unified public blog listing from all curators."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @sort_options [{"Terbaru", "newest"}, {"Terpopuler", "popular"}]

  # These gradient classes MUST live here as literals so Tailwind v4 picks them up.
  # Used by card_gradient_class/1 at runtime.
  @card_gradients [
    "from-violet-500/25 to-fuchsia-600/20",
    "from-blue-500/25 to-cyan-500/20",
    "from-amber-500/25 to-orange-500/20",
    "from-emerald-500/25 to-teal-600/20",
    "from-rose-500/25 to-pink-500/20",
    "from-primary/25 to-secondary/20"
  ]

  @impl true
  def mount(_params, _session, socket) do
    tags = Public.list_popular_blog_tags(24)

    {:ok,
     socket
     |> assign(:page_title, "Curatorial")
     |> assign(:sort_options, @sort_options)
     |> assign(:popular_tags, tags)
     |> assign(:posts, [])
     |> assign(:total_count, 0)
     |> assign(:total_pages, 1)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    search = Map.get(params, "q", "")
    tag = Map.get(params, "tag", nil)
    sort = Map.get(params, "sort", "newest")
    page = String.to_integer(Map.get(params, "page", "1"))

    posts = Public.list_blog_posts(search: search, tag: tag, sort: sort, page: page)
    total = Public.count_blog_posts(search: search, tag: tag)
    total_pages = max(1, ceil(total / Public.page_size()))

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:active_tag, tag)
     |> assign(:sort, sort)
     |> assign(:page, page)
     |> assign(:total_count, total)
     |> assign(:total_pages, total_pages)
     |> assign(:posts, posts)}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    params = build_params(q, socket.assigns.active_tag, socket.assigns.sort, 1)
    {:noreply, push_patch(socket, to: ~p"/blog?#{params}")}
  end

  def handle_event("filter_tag", %{"tag" => tag}, socket) do
    new_tag = if tag == socket.assigns.active_tag, do: nil, else: tag
    params = build_params(socket.assigns.search, new_tag, socket.assigns.sort, 1)
    {:noreply, push_patch(socket, to: ~p"/blog?#{params}")}
  end

  def handle_event("change_sort", %{"sort" => sort}, socket) do
    params = build_params(socket.assigns.search, socket.assigns.active_tag, sort, 1)
    {:noreply, push_patch(socket, to: ~p"/blog?#{params}")}
  end

  def handle_event("goto_page", %{"page" => page_str}, socket) do
    page = String.to_integer(page_str)

    params =
      build_params(socket.assigns.search, socket.assigns.active_tag, socket.assigns.sort, page)

    {:noreply, push_patch(socket, to: ~p"/blog?#{params}")}
  end

  defp build_params(search, tag, sort, page) do
    %{}
    |> then(fn p -> if search != "", do: Map.put(p, "q", search), else: p end)
    |> then(fn p -> if tag, do: Map.put(p, "tag", tag), else: p end)
    |> then(fn p -> if sort != "newest", do: Map.put(p, "sort", sort), else: p end)
    |> then(fn p -> if page > 1, do: Map.put(p, "page", page), else: p end)
  end

  defp page_items(_current, total) when total <= 7, do: Enum.to_list(1..total)

  defp page_items(current, total) do
    cond do
      current <= 4 -> [1, 2, 3, 4, 5, :gap, total]
      current >= total - 3 -> [1, :gap, total - 4, total - 3, total - 2, total - 1, total]
      true -> [1, :gap, current - 1, current, current + 1, :gap, total]
    end
  end

  defp excerpt(nil), do: ""

  defp excerpt(body) do
    body
    |> String.replace(~r/\r?\n+/, " ")
    |> String.replace(~r/[#>*`~\[\]\(\)!\-_]/, "")
    |> String.trim()
    |> String.slice(0, 140)
    |> then(fn s -> if String.length(s) == 140, do: s <> "…", else: s end)
  end

  defp format_date(nil), do: ""

  defp format_date(%DateTime{} = dt) do
    months = ~w(Jan Feb Mar Apr Mei Jun Jul Agu Sep Okt Nov Des)
    "#{dt.day} #{Enum.at(months, dt.month - 1)} #{dt.year}"
  end

  defp format_date(_), do: ""

  defp read_time(nil), do: "1 mnt"

  defp read_time(body) do
    words = body |> String.split(~r/\s+/) |> length()
    minutes = max(1, div(words, 200))
    "#{minutes} mnt"
  end

  defp card_gradient_class(username) do
    idx = (username || "") |> String.to_charlist() |> Enum.sum() |> rem(length(@card_gradients))
    Enum.at(@card_gradients, idx)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <%!-- ── Hero ── --%>
      <div class="relative overflow-hidden border-b border-base-300/50 bg-base-100">
        <div
          aria-hidden="true"
          class="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_80%_60%_at_60%_-10%,oklch(var(--color-primary)/.1),transparent)]"
        >
        </div>
        <div class="relative max-w-6xl mx-auto px-4 sm:px-6 pt-14 pb-10">
          <div class="flex flex-col sm:flex-row sm:items-end gap-6">
            <div class="flex-1">
              <p class="inline-flex items-center gap-1.5 text-xs font-bold text-primary tracking-widest uppercase mb-3">
                <.icon name="hero-rss" class="size-3.5" /> Curatorial
              </p>
              <h1 class="text-3xl sm:text-4xl font-extrabold text-base-content tracking-tight mb-2">
                Curatorial
              </h1>
              <p class="text-base-content/50 text-base max-w-xl leading-relaxed">
                Tulisan, opini, dan pengetahuan dari para profesional pengelola perpustakaan, museum, galeri, dan arsip Indonesia.
              </p>
            </div>

            <div class="w-full sm:w-72 shrink-0">
              <div class="relative">
                <.icon
                  name="hero-magnifying-glass"
                  class="absolute left-3.5 top-1/2 -translate-y-1/2 size-4 text-base-content/35"
                />
                <input
                  id="blog-search"
                  type="text"
                  name="q"
                  value={@search}
                  placeholder="Cari artikel…"
                  phx-keyup="search"
                  phx-debounce="300"
                  class="w-full bg-base-200/60 border border-base-300 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:bg-base-100 focus:outline-none rounded-2xl pl-10 pr-4 h-11 text-sm text-base-content placeholder:text-base-content/35 transition-all duration-200"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="max-w-6xl mx-auto px-4 sm:px-6 py-8">
        <%!-- ── Filter bar ── --%>
        <div class="flex flex-col sm:flex-row sm:items-center gap-3 mb-6">
          <div class="flex-1 overflow-x-auto pb-1 -mb-1">
            <div class="flex items-center gap-2 w-max">
              <button
                phx-click="filter_tag"
                phx-value-tag=""
                class={[
                  "whitespace-nowrap px-3.5 py-1.5 rounded-full text-xs font-bold border transition-all duration-150",
                  is_nil(@active_tag) &&
                    "bg-base-content text-base-100 border-base-content shadow-sm",
                  not is_nil(@active_tag) &&
                    "bg-base-100 border-base-300 text-base-content/55 hover:border-base-content/40 hover:text-base-content"
                ]}
              >
                Semua
              </button>
              <%= for {tag, _cnt} <- @popular_tags do %>
                <button
                  phx-click="filter_tag"
                  phx-value-tag={tag}
                  class={[
                    "whitespace-nowrap px-3.5 py-1.5 rounded-full text-xs font-bold border transition-all duration-150",
                    @active_tag == tag &&
                      "bg-primary text-primary-content border-primary shadow-sm",
                    @active_tag != tag &&
                      "bg-base-100 border-base-300 text-base-content/55 hover:border-primary/40 hover:text-primary hover:bg-primary/8"
                  ]}
                >
                  #{tag}
                </button>
              <% end %>
            </div>
          </div>

          <div class="flex items-center gap-1.5 shrink-0">
            <%= for {label, val} <- @sort_options do %>
              <button
                phx-click="change_sort"
                phx-value-sort={val}
                class={[
                  "px-3.5 py-1.5 rounded-full text-xs font-bold border transition-all duration-150",
                  @sort == val &&
                    "bg-primary/15 text-primary border-primary/30",
                  @sort != val &&
                    "bg-base-100 border-base-300 text-base-content/55 hover:border-primary/30 hover:text-primary"
                ]}
              >
                {label}
              </button>
            <% end %>
          </div>
        </div>

        <%!-- Active filter chip + result count --%>
        <div class="flex items-center justify-between gap-4 mb-8">
          <div class="flex items-center gap-2 flex-wrap">
            <div :if={@active_tag} class="flex items-center gap-1.5">
              <span class="text-xs text-base-content/45">Tag:</span>
              <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold">
                #{@active_tag}
                <button
                  phx-click="filter_tag"
                  phx-value-tag=""
                  class="hover:text-primary/60 transition-colors"
                  aria-label="Hapus filter"
                >
                  <.icon name="hero-x-mark" class="size-3" />
                </button>
              </span>
            </div>
            <div :if={@search != ""} class="flex items-center gap-1.5">
              <span class="text-xs text-base-content/45">Cari:</span>
              <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-base-200 text-base-content/70 text-xs font-bold">
                "{@search}"
                <button
                  phx-click="search"
                  phx-value-q=""
                  class="hover:text-base-content/40 transition-colors"
                  aria-label="Hapus pencarian"
                >
                  <.icon name="hero-x-mark" class="size-3" />
                </button>
              </span>
            </div>
          </div>
          <p :if={@total_count > 0} class="text-xs text-base-content/40 shrink-0">
            {@total_count} artikel
          </p>
        </div>

        <%!-- ── Featured first post (page 1 only) ── --%>
        <%= if @page == 1 && @posts != [] do %>
          <% featured = List.first(@posts) %>
          <.link
            navigate={~p"/u/#{featured.username}/blog/#{featured.slug}"}
            class="group block mb-10"
          >
            <div class="relative flex flex-col sm:flex-row rounded-3xl overflow-hidden bg-base-100 border border-base-300/50 hover:border-primary/30 shadow-md hover:shadow-2xl transition-all duration-400 hover:-translate-y-1">
              <%!-- Image side --%>
              <div class="sm:w-[52%] aspect-[16/9] sm:aspect-auto relative overflow-hidden shrink-0">
                <%= if featured.cover_url do %>
                  <img
                    src={asset_url(featured.cover_url)}
                    alt={featured.title}
                    class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700 ease-out"
                  />
                <% else %>
                  <div class={[
                    "w-full h-full bg-gradient-to-br",
                    card_gradient_class(featured.username)
                  ]}>
                    <div class="w-full h-full flex items-center justify-center">
                      <span class="text-[8rem] font-black text-base-content/5 select-none leading-none">
                        {featured.display_name |> String.first() |> String.upcase()}
                      </span>
                    </div>
                  </div>
                <% end %>
                <%!-- Gradient blend into card on sm+ --%>
                <div class="hidden sm:block absolute inset-y-0 right-0 w-12 bg-gradient-to-l from-base-100 to-transparent">
                </div>
              </div>

              <%!-- Content side --%>
              <div class="flex flex-col justify-between flex-1 px-7 py-7 sm:py-8 sm:pl-4 sm:pr-8">
                <div>
                  <div class="flex items-center gap-2 mb-4">
                    <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-primary/10 text-primary text-[10px] font-extrabold tracking-widest uppercase">
                      <.icon name="hero-star" class="size-2.5" /> Terbaru
                    </span>
                    <%= if featured.tags && featured.tags != [] do %>
                      <span class="text-[10px] text-base-content/35 font-semibold">
                        #{List.first(featured.tags)}
                      </span>
                    <% end %>
                  </div>

                  <h2 class="text-xl sm:text-2xl lg:text-3xl font-extrabold text-base-content leading-tight mb-3 line-clamp-3 group-hover:text-primary transition-colors duration-200">
                    {featured.title}
                  </h2>

                  <p class="text-sm sm:text-base text-base-content/50 leading-relaxed line-clamp-3 mb-6">
                    {excerpt(featured.body)}
                  </p>
                </div>

                <div class="flex items-center justify-between gap-4">
                  <div class="flex items-center gap-3 min-w-0">
                    <div class="size-9 rounded-full overflow-hidden bg-primary/15 shrink-0 flex items-center justify-center ring-2 ring-base-300">
                      <%= if featured.avatar_url do %>
                        <img
                          src={asset_url(featured.avatar_url)}
                          alt={featured.display_name}
                          class="w-full h-full object-cover"
                        />
                      <% else %>
                        <span class="text-sm font-extrabold text-primary">
                          {String.first(featured.display_name || "K")}
                        </span>
                      <% end %>
                    </div>
                    <div class="min-w-0">
                      <p class="text-sm font-bold text-base-content/80 truncate">
                        {featured.display_name || featured.username}
                      </p>
                      <p class="text-xs text-base-content/40">
                        {format_date(featured.published_at)} · {read_time(featured.body)} baca
                      </p>
                    </div>
                  </div>

                  <div class="flex items-center gap-3 text-xs text-base-content/35 shrink-0">
                    <span class="flex items-center gap-1">
                      <.icon name="hero-eye" class="size-3.5" /> {featured.view_count}
                    </span>
                    <span class="flex items-center gap-1">
                      <.icon name="hero-chat-bubble-left-ellipsis" class="size-3.5" />
                      {featured.comment_count}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </.link>
        <% end %>

        <%!-- ── Blog grid ── --%>
        <% grid_posts = if @page == 1, do: Enum.drop(@posts, 1), else: @posts %>

        <div
          :if={grid_posts != []}
          class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6"
        >
          <%= for post <- grid_posts do %>
            <article class="group flex flex-col">
              <.link
                navigate={~p"/u/#{post.username}/blog/#{post.slug}"}
                class="flex flex-col h-full relative bg-base-100 rounded-3xl overflow-hidden border border-base-300/50 hover:border-primary/25 shadow-sm hover:shadow-2xl transition-all duration-300 hover:-translate-y-2"
              >
                <%!-- Accent top border that animates in on hover --%>
                <div class="absolute top-0 left-0 right-0 h-0.5 bg-gradient-to-r from-primary to-secondary origin-left scale-x-0 group-hover:scale-x-100 transition-transform duration-300 z-10">
                </div>

                <%!-- Cover / placeholder --%>
                <div class="relative aspect-[4/3] overflow-hidden shrink-0">
                  <%= if post.cover_url do %>
                    <img
                      src={asset_url(post.cover_url)}
                      alt={post.title}
                      class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 ease-out"
                    />
                    <%!-- Gradient blend into card body --%>
                    <div class="absolute bottom-0 left-0 right-0 h-20 bg-gradient-to-t from-base-100 to-transparent">
                    </div>
                  <% else %>
                    <div class={[
                      "w-full h-full bg-gradient-to-br relative overflow-hidden",
                      card_gradient_class(post.username)
                    ]}>
                      <%!-- Decorative big letter --%>
                      <span class="absolute inset-0 flex items-center justify-center text-[7rem] font-black text-base-content/6 select-none leading-none">
                        {post.display_name |> String.first() |> String.upcase()}
                      </span>
                      <%!-- Decorative circles --%>
                      <div class="absolute -bottom-6 -right-6 w-28 h-28 rounded-full bg-white/5">
                      </div>
                      <div class="absolute -top-3 -left-3 w-14 h-14 rounded-full bg-white/8"></div>
                    </div>
                  <% end %>

                  <%!-- Tag pill --%>
                  <%= if post.tags && post.tags != [] do %>
                    <span class="absolute top-3 left-3 px-2.5 py-1 rounded-full bg-base-100/80 backdrop-blur-sm text-[10px] font-extrabold text-base-content/70 uppercase tracking-wide shadow-sm">
                      {List.first(post.tags)}
                    </span>
                  <% end %>
                </div>

                <%!-- Content --%>
                <div class="flex flex-col flex-1 px-5 pt-4 pb-5">
                  <%!-- Title --%>
                  <h2 class="text-base font-extrabold text-base-content leading-snug mb-2 line-clamp-2 group-hover:text-primary transition-colors duration-200">
                    {post.title}
                  </h2>

                  <%!-- Excerpt --%>
                  <p class="text-[13px] text-base-content/50 leading-relaxed line-clamp-2 mb-4 flex-1">
                    {excerpt(post.body)}
                  </p>

                  <%!-- Author + meta footer --%>
                  <div class="flex items-center justify-between gap-2 pt-3.5 border-t border-base-300/50">
                    <div class="flex items-center gap-2.5 min-w-0">
                      <div class="size-7 rounded-full overflow-hidden bg-primary/15 shrink-0 flex items-center justify-center ring-1 ring-base-300/70">
                        <%= if post.avatar_url do %>
                          <img
                            src={asset_url(post.avatar_url)}
                            alt={post.display_name}
                            class="w-full h-full object-cover"
                          />
                        <% else %>
                          <span class="text-[11px] font-extrabold text-primary">
                            {String.first(post.display_name || "K")}
                          </span>
                        <% end %>
                      </div>
                      <div class="min-w-0">
                        <p class="text-xs font-bold text-base-content/65 truncate leading-none mb-0.5">
                          {post.display_name || post.username}
                        </p>
                        <p class="text-[10px] text-base-content/35 leading-none">
                          {format_date(post.published_at)} · {read_time(post.body)} baca
                        </p>
                      </div>
                    </div>

                    <div class="flex items-center gap-2.5 shrink-0 text-[11px] text-base-content/35">
                      <span class="flex items-center gap-1">
                        <.icon name="hero-eye" class="size-3.5" /> {post.view_count}
                      </span>
                      <span class="flex items-center gap-1">
                        <.icon name="hero-chat-bubble-left-ellipsis" class="size-3.5" />
                        {post.comment_count}
                      </span>
                    </div>
                  </div>
                </div>
              </.link>
            </article>
          <% end %>
        </div>

        <%!-- ── Empty state ── --%>
        <div :if={@posts == []} class="flex flex-col items-center py-28 text-center">
          <div class="size-20 rounded-3xl bg-base-200 flex items-center justify-center mb-5">
            <.icon name="hero-document-magnifying-glass" class="size-10 text-base-content/25" />
          </div>
          <p class="text-base-content/55 text-lg font-bold mb-1">Artikel tidak ditemukan</p>
          <p class="text-base-content/35 text-sm mb-6">
            <%= cond do %>
              <% @search != "" -> %>
                Tidak ada artikel yang cocok dengan "{@search}"
              <% @active_tag != nil -> %>
                Belum ada artikel dengan tag #{@active_tag}
              <% true -> %>
                Belum ada artikel yang tersedia saat ini
            <% end %>
          </p>
          <button
            :if={@search != "" or @active_tag != nil}
            phx-click="filter_tag"
            phx-value-tag=""
            class="px-5 py-2 rounded-full border border-base-300 text-sm text-base-content/55 hover:border-primary/40 hover:text-primary transition-all duration-150 font-medium"
          >
            Hapus semua filter
          </button>
        </div>

        <%!-- ── Pagination ── --%>
        <div :if={@total_pages > 1} class="flex items-center justify-center gap-1.5 mt-14">
          <%!-- Prev --%>
          <button
            :if={@page > 1}
            phx-click="goto_page"
            phx-value-page={@page - 1}
            class="flex items-center gap-1 px-3.5 h-10 rounded-xl border border-base-300 text-sm text-base-content/55 hover:border-primary/40 hover:text-primary hover:bg-primary/5 transition-all duration-150 font-semibold"
          >
            <.icon name="hero-chevron-left" class="size-4" /> Sebelum
          </button>
          <div
            :if={@page == 1}
            class="px-3.5 h-10 rounded-xl text-sm text-base-content/20 flex items-center gap-1 font-semibold cursor-not-allowed"
          >
            <.icon name="hero-chevron-left" class="size-4" /> Sebelum
          </div>

          <%!-- Page numbers --%>
          <%= for item <- page_items(@page, @total_pages) do %>
            <%= if item == :gap do %>
              <span class="w-9 h-10 flex items-center justify-center text-base-content/30 text-sm select-none">
                …
              </span>
            <% else %>
              <button
                phx-click="goto_page"
                phx-value-page={item}
                class={[
                  "w-9 h-10 rounded-xl text-sm font-bold transition-all duration-150",
                  @page == item &&
                    "bg-primary text-primary-content shadow-sm",
                  @page != item &&
                    "text-base-content/60 hover:bg-base-200 hover:text-base-content"
                ]}
              >
                {item}
              </button>
            <% end %>
          <% end %>

          <%!-- Next --%>
          <button
            :if={@page < @total_pages}
            phx-click="goto_page"
            phx-value-page={@page + 1}
            class="flex items-center gap-1 px-3.5 h-10 rounded-xl border border-base-300 text-sm text-base-content/55 hover:border-primary/40 hover:text-primary hover:bg-primary/5 transition-all duration-150 font-semibold"
          >
            Berikut <.icon name="hero-chevron-right" class="size-4" />
          </button>
          <div
            :if={@page >= @total_pages}
            class="px-3.5 h-10 rounded-xl text-sm text-base-content/20 flex items-center gap-1 font-semibold cursor-not-allowed"
          >
            Berikut <.icon name="hero-chevron-right" class="size-4" />
          </div>
        </div>

        <%!-- Page info --%>
        <p :if={@total_pages > 1} class="text-center text-xs text-base-content/35 mt-4">
          Halaman {@page} dari {@total_pages}
        </p>
      </div>
    </Layouts.app>
    """
  end
end
