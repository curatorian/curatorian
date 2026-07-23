defmodule CuratorianWeb.Public.CollectionsLive do
  @moduledoc """
  Flagship cross-node collection discovery page (/collections).

  PostgreSQL full-text search across every published, public collection in the
  network — with faceted filters (GLAM sector, organization, collection type,
  institution type, location) and Dublin Core metadata facets (subject, language,
  creator). Every result is annotated with the organization/node it belongs to.
  """

  use CuratorianWeb, :live_view

  alias Curatorian.Public
  alias CuratorianWeb.Pagination

  # Fields that can be driven from the URL (besides `q`).
  @field_to_atom %{
    "glam_type" => :glam_type,
    "node_id" => :node_id,
    "type" => :type,
    "institution_type" => :institution_type,
    "city" => :city,
    "province" => :province,
    "subject" => :subject,
    "language" => :language,
    "creator" => :creator,
    "sort" => :sort
  }

  @glam_meta %{
    "Library" => %{
      label: "Perpustakaan",
      icon: "hero-book-open",
      badge: "bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/20",
      dot: "bg-blue-500"
    },
    "Museum" => %{
      label: "Museum",
      icon: "hero-building-storefront",
      badge: "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20",
      dot: "bg-amber-500"
    },
    "Archive" => %{
      label: "Arsip",
      icon: "hero-archive-box",
      badge: "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20",
      dot: "bg-emerald-500"
    },
    "Gallery" => %{
      label: "Galeri",
      icon: "hero-photo",
      badge: "bg-pink-500/10 text-pink-600 dark:text-pink-400 border-pink-500/20",
      dot: "bg-pink-500"
    }
  }

  @type_labels %{
    "book" => "Buku",
    "series" => "Seri",
    "movie" => "Film",
    "album" => "Album",
    "course" => "Kursus",
    "other" => "Lainnya"
  }

  @institution_labels %{
    "library" => "Perpustakaan",
    "museum" => "Museum",
    "gallery" => "Galeri",
    "archive" => "Arsip"
  }

  @sort_options [
    {"Paling relevan", "relevance"},
    {"Terbaru", "newest"},
    {"Terlama", "oldest"},
    {"Judul (A - Z)", "title"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Jelajahi Koleksi")
     |> assign(:sort_options, @sort_options)
     |> assign_new(:org_options, fn -> Public.list_org_filter_options() end)
     |> assign_new(:locations, fn -> Public.list_org_locations() end)
     |> assign(:filters_open, false)
     |> assign(:facets, %{})
     |> assign(:filters, empty_filters())}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters = parse_filters(params)
    page = String.to_integer(Map.get(params, "page", "1"))
    opts = to_opts(filters, page)

    collections = Public.search_collections(opts)
    total = Public.count_search_collections(opts)
    page_size = Public.search_page_size()
    total_pages = if total == 0, do: 1, else: ceil(total / page_size)

    # Facets only need to be recomputed on the first page (filters don't
    # change when paginating), so skip the extra queries on later pages.
    facets =
      if page == 1 do
        Public.collection_search_facets(opts)
      else
        socket.assigns[:facets] || %{}
      end

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:page, page)
     |> assign(:total, total)
     |> assign(:total_pages, total_pages)
     |> assign(:facets, facets)
     |> stream(:collections, collections, reset: true)}
  end

  @impl true
  def handle_event("search", %{"value" => value}, socket) do
    {:noreply, push_patch(socket, to: build_path(socket.assigns.filters, q: value, page: 1))}
  end

  def handle_event("filter", %{"field" => field, "val" => value}, socket) do
    key = Map.fetch!(@field_to_atom, field)
    val = if value == "", do: nil, else: value

    {:noreply,
     push_patch(socket, to: build_path(socket.assigns.filters, [{key, val}, {:page, 1}]))}
  end

  def handle_event("select_filter", params, socket) do
    field = Map.fetch!(params, "field")
    key = Map.fetch!(@field_to_atom, field)
    raw = Map.get(params, field)
    val = if raw in [nil, ""], do: nil, else: raw

    {:noreply,
     push_patch(socket, to: build_path(socket.assigns.filters, [{key, val}, {:page, 1}]))}
  end

  def handle_event("clear", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/collections")}
  end

  def handle_event("clear_filter", %{"field" => field}, socket) do
    key = Map.fetch!(@field_to_atom, field)

    {:noreply,
     push_patch(socket, to: build_path(socket.assigns.filters, [{key, nil}, {:page, 1}]))}
  end

  def handle_event("toggle_filters", _params, socket) do
    {:noreply, update(socket, :filters_open, &(!&1))}
  end

  # --- helpers ---

  defp empty_filters,
    do: %{
      q: "",
      glam_type: nil,
      node_id: nil,
      type: nil,
      institution_type: nil,
      city: nil,
      province: nil,
      subject: nil,
      language: nil,
      creator: nil,
      sort: nil
    }

  defp parse_filters(params) do
    %{
      q: (Map.get(params, "q", "") || "") |> to_string(),
      glam_type: empty_to_nil(Map.get(params, "glam_type")),
      node_id: empty_to_nil(Map.get(params, "node_id")),
      type: empty_to_nil(Map.get(params, "type")),
      institution_type: empty_to_nil(Map.get(params, "institution_type")),
      city: empty_to_nil(Map.get(params, "city")),
      province: empty_to_nil(Map.get(params, "province")),
      subject: empty_to_nil(Map.get(params, "subject")),
      language: empty_to_nil(Map.get(params, "language")),
      creator: empty_to_nil(Map.get(params, "creator")),
      sort: empty_to_nil(Map.get(params, "sort"))
    }
  end

  defp empty_to_nil(nil), do: nil
  defp empty_to_nil(""), do: nil
  defp empty_to_nil(v), do: v

  defp to_opts(filters, page) do
    [
      search: filters.q,
      glam_type: filters.glam_type,
      node_id: to_int(filters.node_id),
      collection_type: filters.type,
      institution_type: filters.institution_type,
      city: filters.city,
      province: filters.province,
      subject: filters.subject,
      language: filters.language,
      creator: filters.creator,
      sort: filters.sort,
      page: page,
      page_size: Public.search_page_size()
    ]
  end

  defp build_path(filters, overrides) do
    query =
      filters
      |> Map.merge(Enum.into(overrides, %{}))
      |> Map.put(:page, overrides[:page] || 1)
      |> query_map()

    ~p"/collections?#{query}"
  end

  defp query_map(filters) do
    [
      :q,
      :glam_type,
      :node_id,
      :type,
      :institution_type,
      :city,
      :province,
      :subject,
      :language,
      :creator
    ]
    |> Enum.reduce(%{}, fn key, acc ->
      case Map.get(filters, key) do
        nil -> acc
        "" -> acc
        v -> Map.put(acc, key, v)
      end
    end)
    |> then(fn acc ->
      sort = Map.get(filters, :sort)

      cond do
        sort && sort != "" && sort != "relevance" -> Map.put(acc, :sort, sort)
        true -> acc
      end
    end)
    |> then(fn acc ->
      page = Map.get(filters, :page, 1)

      if page && page > 1 do
        Map.put(acc, :page, page)
      else
        acc
      end
    end)
  end

  defp active_filters(assigns) do
    filters = assigns.filters
    org_name = org_name_for(assigns, filters.node_id)

    []
    |> maybe_chip(:glam_type, filters.glam_type, glam_label(filters.glam_type))
    |> maybe_chip(
      :institution_type,
      filters.institution_type,
      institution_label(filters.institution_type)
    )
    |> maybe_chip(:type, filters.type, Map.get(@type_labels, filters.type, filters.type))
    |> maybe_chip(:node_id, filters.node_id, org_name)
    |> maybe_chip(:province, filters.province, filters.province)
    |> maybe_chip(:city, filters.city, filters.city)
    |> maybe_chip(:subject, filters.subject, filters.subject)
    |> maybe_chip(:language, filters.language, filters.language)
    |> maybe_chip(:creator, filters.creator, filters.creator)
    |> Enum.reject(&is_nil/1)
  end

  defp maybe_chip(list, _field, nil, _label), do: list
  defp maybe_chip(list, _field, "", _label), do: list
  defp maybe_chip(list, field, _value, label), do: list ++ [%{field: field, label: label}]

  defp org_name_for(assigns, node_id) when not is_nil(node_id) do
    id =
      case node_id do
        v when is_integer(v) -> v
        v -> String.to_integer(v)
      end

    case Enum.find(assigns.org_options, &(&1.node_id == id)) do
      nil -> "Organisasi"
      org -> org.name
    end
  end

  defp org_name_for(_assigns, _node_id), do: nil

  defp glam_label(nil), do: nil
  defp glam_label(g), do: get_in(@glam_meta, [g, :label]) || g

  defp institution_label(nil), do: nil
  defp institution_label(i), do: Map.get(@institution_labels, i, i)

  defp type_label(v), do: Map.get(@type_labels, v, v)

  defp glam_dot(value), do: get_in(@glam_meta, [value, :dot]) || "bg-base-content/30"

  defp to_int(nil), do: nil

  defp to_int(value) when is_integer(value), do: value

  defp to_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {n, ""} -> n
      _ -> nil
    end
  end

  defp facet_active?(filters, field, value) do
    to_string(Map.get(filters, field)) == to_string(value)
  end

  defp format_count(n) when n >= 1000, do: "#{div(n, 1000)}rb"
  defp format_count(n), do: "#{n}"

  defp any_filters?(filters) do
    Enum.any?(
      [
        :glam_type,
        :node_id,
        :type,
        :institution_type,
        :city,
        :province,
        :subject,
        :language,
        :creator
      ],
      fn k ->
        Map.get(filters, k) not in [nil, ""]
      end
    )
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :active, active_filters(assigns))

    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Page header --%>
        <div class="mb-8 relative">
          <div
            aria-hidden="true"
            class="pointer-events-none absolute -top-6 -right-6 size-48 rounded-full bg-accent/10 blur-3xl"
          >
          </div>
          <div
            aria-hidden="true"
            class="pointer-events-none absolute -bottom-2 -left-2 size-32 rounded-full bg-primary/10 blur-3xl"
          >
          </div>
          <div class="relative">
            <p class="text-xs font-semibold uppercase tracking-widest text-primary mb-2">
              Jaringan GLAM
            </p>
            <h1 class="text-3xl sm:text-4xl font-semibold text-base-content mb-2">
              Jelajahi Koleksi
            </h1>
            <p class="text-base-content/60 text-base leading-relaxed max-w-2xl">
              Temukan koleksi terkurasi dari perpustakaan, museum, galeri, dan arsip di seluruh jaringan —
              setiap koleksi menampilkan institusi pemiliknya.
            </p>
          </div>
        </div>

        <%!-- Search bar --%>
        <div class="relative mb-5">
          <.icon
            name="hero-magnifying-glass"
            class="absolute left-4 top-1/2 -translate-y-1/2 size-5 text-base-content/40 pointer-events-none"
          />
          <input
            id="discover-search"
            type="text"
            name="q"
            value={@filters.q}
            placeholder="Cari judul, deskripsi, subjek, atau penulis…"
            class="w-full h-12 bg-base-100 border border-base-300 focus:border-primary focus:outline-none focus:ring-4 focus:ring-primary/10 rounded-2xl pl-12 pr-4 text-sm text-base-content placeholder:text-base-content/40 transition-all duration-200 shadow-sm"
            phx-keyup="search"
            phx-debounce="300"
          />
        </div>

        <%!-- Active filter chips + count + clear --%>
        <div class="flex flex-wrap items-center gap-2 mb-5">
          <span class="text-sm text-base-content/50 mr-1">
            <span class="font-semibold text-base-content">{@total}</span> koleksi
          </span>

          <.link
            :for={chip <- @active}
            id={"active-chip-#{chip.field}"}
            phx-click="clear_filter"
            phx-value-field={chip.field}
            class="inline-flex items-center gap-1.5 rounded-full bg-primary/10 text-primary pl-3 pr-2 py-1 text-xs font-medium hover:bg-primary/20 transition-colors cursor-pointer"
          >
            {chip.label}
            <.icon name="hero-x-mark" class="size-3.5" />
          </.link>

          <button
            :if={any_filters?(@filters)}
            phx-click="clear"
            class="text-xs text-base-content/50 hover:text-error underline underline-offset-2 transition-colors"
          >
            Hapus semua filter
          </button>

          <div class="ml-auto flex items-center gap-2">
            <button
              type="button"
              phx-click="toggle_filters"
              class="lg:hidden inline-flex items-center gap-1.5 rounded-xl border border-base-300 px-3 py-1.5 text-xs font-medium text-base-content/70 hover:bg-base-200 transition-colors"
            >
              <.icon name="hero-funnel" class="size-4" /> Filter
            </button>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-[280px_minmax(0,1fr)] gap-8 items-start">
          <%!-- Filters sidebar --%>
          <aside
            id="filters-sidebar"
            class={[
              "lg:sticky lg:top-24 space-y-6",
              (@filters_open && "block") || "hidden lg:block"
            ]}
          >
            <.filters
              filters={@filters}
              facets={@facets}
              org_options={@org_options}
              locations={@locations}
              sort_options={@sort_options}
            />
          </aside>

          <%!-- Results --%>
          <div class="min-w-0">
            <div
              :if={@total == 0}
              class="rounded-2xl border border-dashed border-base-300 bg-base-100 p-12 text-center"
            >
              <div class="mx-auto mb-4 flex size-14 items-center justify-center rounded-2xl bg-base-200">
                <.icon name="hero-magnifying-glass" class="size-7 text-base-content/40" />
              </div>
              <h3 class="text-base font-semibold text-base-content">Tidak ada koleksi ditemukan</h3>
              <p class="mt-1 text-sm text-base-content/60">
                Coba ubah kata kunci atau hapus beberapa filter.
              </p>
              <button
                phx-click="clear"
                class="mt-4 inline-flex items-center gap-1.5 rounded-xl bg-primary px-4 py-2 text-sm font-medium text-primary-content hover:bg-primary-focus transition-colors"
              >
                Reset pencarian
              </button>
            </div>

            <div
              id="collections"
              class={[
                "grid gap-5",
                @total > 0 && "grid-cols-1 sm:grid-cols-2 xl:grid-cols-3"
              ]}
              phx-update="stream"
            >
              <div :for={{id, col} <- @streams.collections} id={id}>
                <.collection_card col={col} />
              </div>
            </div>

            <Pagination.pagination
              :if={@total_pages > 1}
              current={@page}
              total_pages={@total_pages}
              path={fn p -> page_path(@filters, p) end}
              class="mt-10"
            />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # --- components ---

  defp filters(assigns) do
    ~H"""
    <div class="lg:bg-transparent bg-base-100 lg:shadow-none rounded-2xl lg:rounded-none p-4 lg:p-0">
      <div class="flex items-center justify-between lg:hidden mb-4">
        <h2 class="text-sm font-semibold">Filter</h2>
        <button phx-click="toggle_filters" class="text-base-content/50">
          <.icon name="hero-x-mark" class="size-5" />
        </button>
      </div>

      <%!-- Sort --%>
      <.filter_section title="Urutkan">
        <select
          name="sort"
          phx-change="select_filter"
          phx-value-field="sort"
          class="w-full select select-bordered select-sm bg-base-100"
        >
          <.option
            :for={{label, value} <- @sort_options}
            value={value}
            selected={(@filters.sort || "relevance") == value}
          >
            {label}
          </.option>
        </select>
      </.filter_section>

      <%!-- GLAM sector --%>
      <.facet_list
        title="Sektor GLAM"
        field="glam_type"
        filters={@filters}
        values={@facets[:glam_types] || []}
        labeler={&glam_label/1}
        show_icon
      />
      <%!-- Organization --%>
      <.filter_section title="Organisasi">
        <select
          name="node_id"
          phx-change="select_filter"
          phx-value-field="node_id"
          class="w-full select select-bordered select-sm bg-base-100"
        >
          <option value="">Semua organisasi</option>
          <.option
            :for={org <- @org_options}
            value={org.node_id}
            selected={to_string(@filters.node_id) == to_string(org.node_id)}
          >
            {org.name} ({org.count})
          </.option>
        </select>
      </.filter_section>

      <%!-- Collection type --%>
      <.facet_list
        title="Jenis Koleksi"
        field="type"
        filters={@filters}
        values={@facets[:collection_types] || []}
        labeler={&type_label/1}
      />

      <%!-- Institution type --%>
      <.facet_list
        title="Jenis Institusi"
        field="institution_type"
        filters={@filters}
        values={@facets[:institution_types] || []}
        labeler={&institution_label/1}
      />

      <%!-- Location --%>
      <.filter_section title="Lokasi">
        <div class="space-y-2">
          <select
            name="province"
            phx-change="select_filter"
            phx-value-field="province"
            class="w-full select select-bordered select-sm bg-base-100"
          >
            <option value="">Semua provinsi</option>
            <.option
              :for={loc <- @locations[:provinces] || []}
              value={loc.value}
              selected={to_string(@filters.province) == to_string(loc.value)}
            >
              {loc.value} ({loc.count})
            </.option>
          </select>

          <select
            name="city"
            phx-change="select_filter"
            phx-value-field="city"
            class="w-full select select-bordered select-sm bg-base-100"
          >
            <option value="">Semua kota</option>
            <.option
              :for={loc <- @locations[:cities] || []}
              value={loc.value}
              selected={to_string(@filters.city) == to_string(loc.value)}
            >
              {loc.value} ({loc.count})
            </.option>
          </select>
        </div>
      </.filter_section>

      <%!-- Dublin Core facets --%>
      <.facet_list
        :if={@facets[:subjects] != []}
        title="Subjek"
        field="subject"
        filters={@filters}
        values={@facets[:subjects] || []}
      />
      <.facet_list
        :if={@facets[:languages] != []}
        title="Bahasa"
        field="language"
        filters={@filters}
        values={@facets[:languages] || []}
      />
      <.facet_list
        :if={@facets[:creators] != []}
        title="Kreator / Penulis"
        field="creator"
        filters={@filters}
        values={@facets[:creators] || []}
      />
    </div>
    """
  end

  attr :title, :string, required: true
  slot :inner_block, required: true

  defp filter_section(assigns) do
    ~H"""
    <div class="pb-5 border-b border-base-200">
      <h3 class="text-xs font-semibold uppercase tracking-wide text-base-content/50 mb-3">
        {@title}
      </h3>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :title, :string, required: true
  attr :field, :string, required: true
  attr :filters, :map, required: true
  attr :values, :list, required: true
  attr :labeler, :any, default: nil
  attr :show_icon, :boolean, default: false

  defp facet_list(assigns) do
    ~H"""
    <div class="pb-5 border-b border-base-200">
      <h3 class="text-xs font-semibold uppercase tracking-wide text-base-content/50 mb-3">
        {@title}
      </h3>
      <div class="space-y-0.5 max-h-52 overflow-y-auto pr-1">
        <button
          :for={item <- @values}
          phx-click="filter"
          phx-value-field={@field}
          phx-value-val={item.value}
          class={[
            "flex w-full items-center gap-2 rounded-lg px-2.5 py-1.5 text-sm transition-colors text-left",
            facet_active?(@filters, @field, item.value) &&
              "bg-primary/10 text-primary font-medium",
            !facet_active?(@filters, @field, item.value) &&
              "text-base-content/70 hover:bg-base-200"
          ]}
        >
          <%= if @show_icon do %>
            <span class={["size-2 rounded-full shrink-0", glam_dot(item.value)]}></span>
          <% end %>
          <span class="truncate flex-1">
            {if @labeler, do: @labeler.(item.value), else: item.value}
          </span>
          <span class="text-xs text-base-content/40 shrink-0">{format_count(item.count)}</span>
        </button>
      </div>
    </div>
    """
  end

  attr :value, :string, default: nil
  attr :selected, :boolean, default: false
  slot :inner_block, required: true

  defp option(assigns) do
    ~H"""
    <option value={@value} selected={@selected}>
      {render_slot(@inner_block)}
    </option>
    """
  end

  defp collection_card(assigns) do
    col = assigns.col
    glam_type = col.resource_class && col.resource_class.glam_type
    glam_meta = glam_type && Map.get(@glam_meta, glam_type)
    type_label = Map.get(@type_labels, col.collection_type)

    assigns =
      assigns
      |> assign(:glam_type, glam_type)
      |> assign(:glam_meta, glam_meta)
      |> assign(:type_label, type_label)

    ~H"""
    <div class="group bg-base-100 rounded-2xl border border-base-300/70 hover:border-primary/30 shadow-sm hover:shadow-lg hover:-translate-y-0.5 transition-all duration-300 overflow-hidden flex flex-col">
      <figure class="relative h-44 overflow-hidden bg-gradient-to-br from-primary/10 to-accent/15">
        <%= if @col.thumbnail do %>
          <img
            src={asset_url(@col.thumbnail)}
            alt={@col.title}
            class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            loading="lazy"
          />
        <% else %>
          <div class="w-full h-full flex items-center justify-center">
            <.icon name="hero-rectangle-stack" class="size-12 text-primary/30" />
          </div>
        <% end %>

        <%= if @glam_meta do %>
          <span class={[
            "absolute top-3 left-3 inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-[11px] font-semibold backdrop-blur-md bg-base-100/80",
            @glam_meta.badge
          ]}>
            <.icon name={@glam_meta.icon} class="size-3" />
            {@glam_meta.label}
          </span>
        <% end %>
      </figure>

      <div class="p-4 space-y-2.5 flex flex-col flex-1">
        <div class="flex items-start justify-between gap-2">
          <h3 class="font-semibold text-sm leading-snug line-clamp-2 text-base-content">
            {@col.title}
          </h3>
          <span
            :if={@type_label}
            class="text-[11px] bg-base-200 text-base-content/70 px-2 py-0.5 rounded-full shrink-0"
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

        <div class="flex-1"></div>

        <div class="pt-2 border-t border-base-200/70 flex items-center gap-2">
          <span class="flex size-7 items-center justify-center rounded-lg bg-primary/10 text-primary shrink-0">
            <.icon name="hero-building-library" class="size-3.5" />
          </span>
          <div class="min-w-0">
            <p
              :if={@col.unit}
              class="text-xs font-medium text-base-content/80 truncate"
              title={@col.unit && @col.unit.name}
            >
              {@col.unit.name}
            </p>
            <p
              :if={@col.collection_code}
              class="text-[10px] font-mono text-base-content/40 truncate"
            >
              {@col.collection_code}
            </p>
          </div>
        </div>

        <div class="pt-1">
          <.link
            navigate={~p"/collections/#{@col.id}"}
            class="flex items-center justify-center gap-1.5 w-full py-2 rounded-xl text-xs font-semibold text-primary border border-primary/30 group-hover:bg-primary group-hover:text-primary-content group-hover:border-primary transition-all duration-200"
          >
            Lihat koleksi <.icon name="hero-arrow-right" class="size-3.5" />
          </.link>
        </div>
      </div>
    </div>
    """
  end

  defp page_path(filters, page), do: build_path(filters, page: page)
end
