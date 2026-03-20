defmodule CuratorianWeb.Public.CollectionsLive do
  @moduledoc "Public listing page for collections (/collections)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @type_options [
    {"Semua", nil},
    {"Buku", "book"},
    {"Seri", "series"},
    {"Film", "movie"},
    {"Album", "album"},
    {"Kursus", "course"},
    {"Lainnya", "other"}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Koleksi")
     |> assign(:type_options, @type_options)}
  end

  def handle_params(params, _uri, socket) do
    search = Map.get(params, "q", "")
    collection_type = Map.get(params, "type", nil)
    collection_type = if collection_type == "", do: nil, else: collection_type
    page = String.to_integer(Map.get(params, "page", "1"))

    collections = Public.list_collections(search, page: page, collection_type: collection_type)

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:collection_type, collection_type)
     |> assign(:page, page)
     |> assign(:has_more, length(collections) == Public.page_size())
     |> stream(:collections, collections, reset: true)}
  end

  def handle_event("search", %{"q" => q}, socket) do
    params = build_params(q, socket.assigns.collection_type, 1)
    {:noreply, push_patch(socket, to: ~p"/collections?#{params}")}
  end

  def handle_event("filter_type", %{"type" => type}, socket) do
    type_val = if type == "", do: nil, else: type
    params = build_params(socket.assigns.search, type_val, 1)
    {:noreply, push_patch(socket, to: ~p"/collections?#{params}")}
  end

  def handle_event("load_more", _, socket) do
    next_page = socket.assigns.page + 1

    collections =
      Public.list_collections(socket.assigns.search,
        page: next_page,
        collection_type: socket.assigns.collection_type
      )

    {:noreply,
     socket
     |> assign(:page, next_page)
     |> assign(:has_more, length(collections) == Public.page_size())
     |> stream(:collections, collections)}
  end

  defp build_params(search, collection_type, page) do
    %{}
    |> then(fn p -> if search != "", do: Map.put(p, "q", search), else: p end)
    |> then(fn p -> if collection_type, do: Map.put(p, "type", collection_type), else: p end)
    |> then(fn p -> if page > 1, do: Map.put(p, "page", page), else: p end)
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto py-8 px-4">
        <%!-- Page header --%>
        <div class="mb-10 relative animate-fade-in">
          <div
            aria-hidden="true"
            class="pointer-events-none absolute -top-6 -right-6 size-48 rounded-full bg-accent/8 blur-3xl"
          >
          </div>
          <div
            aria-hidden="true"
            class="pointer-events-none absolute -bottom-2 -left-2 size-32 rounded-full bg-primary/8 blur-3xl"
          >
          </div>
          <h1 class="text-3xl sm:text-4xl font-semibold text-base-content mb-2">Koleksi</h1>
          <p class="text-base-content/60 text-base leading-relaxed">
            Jelajahi koleksi kurasi dari berbagai institusi dan kurator
          </p>
        </div>

        <%!-- Search bar --%>
        <div class="relative mb-4">
          <.icon
            name="hero-magnifying-glass"
            class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-base-content/40"
          />
          <input
            id="collection-search"
            type="text"
            name="q"
            value={@search}
            placeholder="Cari koleksi berdasarkan judul atau deskripsi..."
            class="w-full bg-base-100 border border-base-300 focus:border-primary focus:outline-none rounded-xl pl-10 pr-4 h-11 text-sm text-base-content placeholder:text-base-content/40 transition-colors duration-150"
            phx-change="search"
            phx-debounce="300"
          />
        </div>

        <%!-- Type filter --%>
        <div class="flex gap-2 flex-wrap mb-6 pb-4 border-b border-base-300/60">
          <%= for {label, val} <- @type_options do %>
            <button
              phx-click="filter_type"
              phx-value-type={val || ""}
              class={[
                "px-3.5 py-1.5 rounded-full text-sm font-medium transition-all duration-150",
                @collection_type == val &&
                  "bg-primary text-primary-content shadow-sm",
                @collection_type != val &&
                  "text-base-content/60 border border-base-300 hover:border-primary/40 hover:text-base-content hover:bg-primary/5"
              ]}
            >
              {label}
            </button>
          <% end %>
        </div>

        <%!-- Results grid --%>
        <div
          id="collections"
          class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5"
          phx-update="stream"
        >
          <div :for={{id, col} <- @streams.collections} id={id}>
            <.collection_card col={col} />
          </div>
        </div>

        <%!-- Load more --%>
        <div :if={@has_more} class="flex justify-center mt-10">
          <button
            phx-click="load_more"
            class="inline-flex items-center gap-2 px-8 py-2.5 rounded-full border border-primary/50 text-primary text-sm font-medium hover:bg-primary hover:text-primary-content transition-all duration-200"
          >
            <.icon name="hero-arrow-down" class="size-4" /> Muat lebih banyak
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @type_labels %{
    "book" => "Buku",
    "series" => "Seri",
    "movie" => "Film",
    "album" => "Album",
    "course" => "Kursus",
    "other" => "Lainnya"
  }

  defp collection_card(assigns) do
    assigns =
      assign(assigns, :type_label, Map.get(@type_labels, assigns.col.collection_type, nil))

    ~H"""
    <div class="group bg-base-100 rounded-2xl border border-base-300/70 hover:border-primary/30 shadow-sm hover:shadow-md hover:-translate-y-0.5 transition-all duration-300 overflow-hidden">
      <%!-- Thumbnail --%>
      <figure class="h-40 overflow-hidden bg-gradient-to-br from-primary/10 to-accent/15">
        <%= if @col.thumbnail do %>
          <img src={asset_url(@col.thumbnail)} alt={@col.title} class="w-full h-full object-cover" />
        <% else %>
          <div class="w-full h-full flex items-center justify-center">
            <.icon name="hero-rectangle-stack" class="size-12 text-primary/30" />
          </div>
        <% end %>
      </figure>

      <div class="p-4 space-y-2">
        <div class="flex items-start justify-between gap-2">
          <h3 class="font-semibold text-sm leading-snug line-clamp-2 text-base-content">
            {@col.title}
          </h3>
          <span
            :if={@type_label}
            class="text-xs bg-accent/10 text-accent px-2 py-0.5 rounded-full shrink-0"
          >
            {@type_label}
          </span>
        </div>

        <p
          :if={@col.description}
          class="text-xs text-base-content/60 line-clamp-2 leading-relaxed"
        >
          {@col.description}
        </p>

        <p
          :if={@col.unit}
          class="text-xs text-base-content/50 flex items-center gap-1"
        >
          <.icon name="hero-building-library-micro" class="size-3 shrink-0" />
          <span class="truncate">{@col.unit.name}</span>
        </p>

        <p
          :if={@col.collection_code}
          class="text-xs font-mono text-base-content/40"
        >
          {@col.collection_code}
        </p>

        <div class="pt-1">
          <.link
            navigate={~p"/collections/#{@col.id}"}
            class="flex items-center justify-center gap-1.5 w-full py-1.5 rounded-xl text-xs font-medium text-primary border border-primary/30 group-hover:bg-primary group-hover:text-primary-content group-hover:border-primary transition-all duration-200"
          >
            Lihat Koleksi
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
