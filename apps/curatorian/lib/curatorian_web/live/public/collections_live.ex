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
        <div class="mb-8">
          <h1 class="text-4xl font-bold text-base-content mb-2">Koleksi</h1>
          <p class="text-base-content/60 text-lg">
            Jelajahi koleksi kurasi dari berbagai institusi dan kurator
          </p>
        </div>

        <%!-- Search bar --%>
        <div class="relative mb-4">
          <.icon
            name="hero-magnifying-glass"
            class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-base-content/40"
          />
          <input
            id="collection-search"
            type="text"
            name="q"
            value={@search}
            placeholder="Cari koleksi berdasarkan judul atau deskripsi..."
            class="input input-bordered w-full pl-10"
            phx-change="search"
            phx-debounce="300"
          />
        </div>

        <%!-- Type filter --%>
        <div class="flex gap-2 flex-wrap mb-6 pb-4 border-b border-base-300">
          <%= for {label, val} <- @type_options do %>
            <button
              phx-click="filter_type"
              phx-value-type={val || ""}
              class={[
                "btn btn-sm",
                @collection_type == val && "btn-primary",
                @collection_type != val && "btn-ghost border border-base-300"
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
          <button phx-click="load_more" class="btn btn-outline btn-primary px-10">
            Muat lebih banyak
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
    <div class="card bg-base-100 shadow border border-base-300 hover:shadow-xl hover:-translate-y-0.5 transition-all duration-300 overflow-hidden">
      <%!-- Thumbnail --%>
      <figure class="h-40 overflow-hidden bg-gradient-to-br from-violet-100 to-purple-200 dark:from-violet-900 dark:to-purple-800">
        <%= if @col.thumbnail do %>
          <img src={asset_url(@col.thumbnail)} alt={@col.title} class="w-full h-full object-cover" />
        <% else %>
          <div class="w-full h-full flex items-center justify-center">
            <.icon name="hero-rectangle-stack" class="w-12 h-12 text-violet-300 dark:text-violet-500" />
          </div>
        <% end %>
      </figure>

      <div class="card-body p-4 gap-2">
        <div class="flex items-start justify-between gap-2">
          <h3 class="font-bold text-sm leading-snug line-clamp-2">{@col.title}</h3>
          <span
            :if={@type_label}
            class="badge badge-sm badge-secondary shrink-0"
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
          <.icon name="hero-building-library-micro" class="w-3 h-3 shrink-0" />
          <span class="truncate">{@col.unit.name}</span>
        </p>

        <p
          :if={@col.collection_code}
          class="text-xs font-mono text-base-content/40"
        >
          {@col.collection_code}
        </p>

        <div class="card-actions mt-1">
          <.link
            navigate={~p"/collections/#{@col.id}"}
            class="btn btn-xs btn-outline btn-primary w-full"
          >
            Lihat Koleksi
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
