defmodule CuratorianWeb.Public.OrganizationsLive do
  @moduledoc "Public listing page for organizations (/orgs)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @institution_type_options [
    {"Semua", nil},
    {"Perpustakaan", :library},
    {"Museum", :museum},
    {"Galeri", :gallery},
    {"Arsip", :archive}
  ]

  @institution_type_labels %{
    library: "Perpustakaan",
    museum: "Museum",
    gallery: "Galeri",
    archive: "Arsip"
  }

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Organisasi")
     |> assign(:institution_type_options, @institution_type_options)
     |> assign(:institution_type_labels, @institution_type_labels)
     |> assign(:searching, false)}
  end

  def handle_params(params, _uri, socket) do
    search = Map.get(params, "q", "")
    institution_type = params |> Map.get("type", nil) |> parse_institution_type()
    page = String.to_integer(Map.get(params, "page", "1"))

    orgs = Public.list_node_profiles(search, page: page, institution_type: institution_type)

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:institution_type, institution_type)
     |> assign(:page, page)
     |> assign(:org_count, length(orgs))
     |> assign(:searching, false)
     |> assign(:has_more, length(orgs) == Public.page_size())
     |> stream(:orgs, orgs |> Enum.map(&flatten_org/1), reset: true)}
  end

  def handle_event("search", %{"q" => q}, socket) do
    params = build_params(q, socket.assigns.institution_type, 1)
    {:noreply, socket |> assign(:searching, true) |> push_patch(to: ~p"/orgs?#{params}")}
  end

  def handle_event("search", %{"value" => value}, socket) when is_binary(value) do
    params = build_params(value, socket.assigns.institution_type, 1)
    {:noreply, socket |> assign(:searching, true) |> push_patch(to: ~p"/orgs?#{params}")}
  end

  def handle_event("filter_type", %{"type" => type}, socket) do
    institution_type = parse_institution_type(type)
    params = build_params(socket.assigns.search, institution_type, 1)
    {:noreply, push_patch(socket, to: ~p"/orgs?#{params}")}
  end

  def handle_event("load_more", _, socket) do
    next_page = socket.assigns.page + 1

    orgs =
      Public.list_node_profiles(socket.assigns.search,
        page: next_page,
        institution_type: socket.assigns.institution_type
      )

    {:noreply,
     socket
     |> assign(:page, next_page)
     |> assign(:has_more, length(orgs) == Public.page_size())
     |> stream(:orgs, orgs |> Enum.map(&flatten_org/1))}
  end

  # Merge %{profile: node_profile, node: voile_node} into a flat map for the template
  defp flatten_org(%{profile: profile, node: node}) do
    %{
      id: profile.id,
      name: profile.institution_name || node.name,
      abbr: node.abbr,
      node_image: Public.asset_url(node.image),
      institution_type: profile.institution_type,
      node_type: profile.node_type,
      city: profile.city,
      province: profile.province,
      website: profile.website,
      phone: profile.phone,
      address: profile.address
    }
  end

  defp parse_institution_type(nil), do: nil
  defp parse_institution_type(""), do: nil

  defp parse_institution_type(type) when is_binary(type) do
    valid = [:library, :museum, :gallery, :archive]
    atom = String.to_existing_atom(type)
    if atom in valid, do: atom, else: nil
  rescue
    ArgumentError -> nil
  end

  defp parse_institution_type(type) when is_atom(type), do: type

  defp build_params(search, institution_type, page) do
    %{}
    |> then(fn p -> if search != "", do: Map.put(p, "q", search), else: p end)
    |> then(fn p -> if institution_type, do: Map.put(p, "type", institution_type), else: p end)
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
            class="pointer-events-none absolute -top-6 -right-6 size-48 rounded-full bg-secondary/8 blur-3xl"
          >
          </div>
          <div
            aria-hidden="true"
            class="pointer-events-none absolute -bottom-2 -left-2 size-32 rounded-full bg-primary/8 blur-3xl"
          >
          </div>
          <h1 class="text-3xl sm:text-4xl font-semibold text-base-content mb-2">Organisasi</h1>
          <p class="text-base-content/60 text-base leading-relaxed">
            Temukan perpustakaan, museum, galeri, dan institusi pengelola koleksi
          </p>
        </div>

        <%!-- Search bar --%>
        <div class="relative mb-4">
          <.icon
            name="hero-magnifying-glass"
            class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-base-content/40"
          />
          <input
            id="org-search"
            type="text"
            name="q"
            value={@search}
            placeholder="Cari organisasi berdasarkan nama atau kota..."
            class="w-full bg-base-100 border border-base-300 focus:border-primary focus:outline-none rounded-xl pl-10 pr-4 h-11 text-sm text-base-content placeholder:text-base-content/40 transition-colors duration-150"
            phx-keyup="search"
            phx-debounce="300"
          />
        </div>

        <%!-- Institution type filter --%>
        <div class="flex gap-2 flex-wrap mb-6 pb-4 border-b border-base-300/60">
          <%= for {label, val} <- @institution_type_options do %>
            <button
              phx-click="filter_type"
              phx-value-type={val || ""}
              class={[
                "px-3.5 py-1.5 rounded-full text-sm font-medium transition-all duration-150",
                @institution_type == val &&
                  "bg-primary text-primary-content shadow-sm",
                @institution_type != val &&
                  "text-base-content/60 border border-base-300 hover:border-primary/40 hover:text-base-content hover:bg-primary/5"
              ]}
            >
              {label}
            </button>
          <% end %>
        </div>

        <%= if @searching do %>
          <div class="py-10 text-center text-base-content/60">
            Mencari organisasi untuk "#{@search}" ...
          </div>
        <% end %>

        <%= if not @searching and @org_count == 0 and @search != "" do %>
          <div class="py-10 text-center text-base-content/60">
            Tidak ada organisasi ditemukan untuk "#{@search}"
          </div>
        <% end %>

        <%!-- Results grid --%>
        <div
          id="orgs"
          class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5"
          phx-update="stream"
        >
          <div :for={{id, org} <- @streams.orgs} id={id}>
            <.org_card org={org} institution_type_labels={@institution_type_labels} />
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

  defp org_card(assigns) do
    assigns =
      assign(
        assigns,
        :type_label,
        Map.get(assigns.institution_type_labels, assigns.org.institution_type, nil)
      )

    ~H"""
    <div class="group bg-base-100 rounded-2xl border border-base-300/70 hover:border-primary/30 shadow-sm hover:shadow-md hover:-translate-y-0.5 transition-all duration-300 overflow-hidden">
      <%!-- Cover placeholder --%>
      <div class="h-24 overflow-hidden">
        <div class="w-full h-full bg-gradient-to-br from-secondary/25 to-primary/35"></div>
      </div>

      <div class="px-4 pb-4 pt-0 -mt-8">
        <%!-- Avatar / logo --%>
        <div class="w-16 h-16 rounded-xl ring-4 ring-base-100 overflow-hidden bg-primary/15 flex items-center justify-center">
          <%= if @org.node_image do %>
            <img src={@org.node_image} alt={@org.name} class="w-full h-full object-cover" />
          <% else %>
            <span class="text-2xl font-bold text-primary/80">
              {String.first(@org.name || "O")}
            </span>
          <% end %>
        </div>

        <div class="mt-2">
          <h3 class="font-semibold text-base leading-tight line-clamp-1 text-base-content">
            {@org.name}
          </h3>
          <span :if={@org.abbr} class="text-xs text-base-content/50">{@org.abbr}</span>
          <div :if={@type_label} class="mt-1">
            <span class="text-xs bg-secondary/10 text-secondary px-2 py-0.5 rounded-full">
              {@type_label}
            </span>
          </div>
        </div>

        <p
          :if={@org.city}
          class="text-xs text-base-content/50 flex items-center gap-1 mt-2"
        >
          <.icon name="hero-map-pin-micro" class="size-3 shrink-0" />
          <span class="truncate">
            {@org.city}
            <%= if @org.province do %>
              , {@org.province}
            <% end %>
          </span>
        </p>

        <div class="mt-3">
          <.link
            navigate={~p"/orgs/#{@org.id}"}
            class="flex items-center justify-center gap-1.5 w-full py-2 rounded-xl text-sm font-medium text-primary border border-primary/30 group-hover:bg-primary group-hover:!text-primary-content group-hover:border-primary transition-all duration-200"
          >
            Lihat Organisasi
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
