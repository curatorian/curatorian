defmodule CuratorianWeb.Public.ProfilesLive do
  @moduledoc "Public listing page for curator profiles (/kurator)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @institution_type_options [
    {"Semua", nil},
    {"Perpustakaan", "library"},
    {"Museum", "museum"},
    {"Galeri", "gallery"},
    {"Arsip", "archive"}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Kurator")
     |> assign(:institution_type_options, @institution_type_options)}
  end

  def handle_params(params, _uri, socket) do
    search = Map.get(params, "q", "")
    institution_type = Map.get(params, "type", nil)
    page = String.to_integer(Map.get(params, "page", "1"))

    profiles = Public.list_profiles(search, page: page, institution_type: institution_type)

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:institution_type, institution_type)
     |> assign(:page, page)
     |> assign(:has_more, length(profiles) == Public.page_size())
     |> stream(:profiles, profiles, reset: true)}
  end

  def handle_event("search", %{"q" => q}, socket) do
    params = build_params(q, socket.assigns.institution_type, 1)
    {:noreply, push_patch(socket, to: ~p"/kurator?#{params}")}
  end

  def handle_event("filter_type", %{"type" => type}, socket) do
    type_val = if type == "", do: nil, else: type
    params = build_params(socket.assigns.search, type_val, 1)
    {:noreply, push_patch(socket, to: ~p"/kurator?#{params}")}
  end

  def handle_event("load_more", _, socket) do
    next_page = socket.assigns.page + 1

    profiles =
      Public.list_profiles(socket.assigns.search,
        page: next_page,
        institution_type: socket.assigns.institution_type
      )

    {:noreply,
     socket
     |> assign(:page, next_page)
     |> assign(:has_more, length(profiles) == Public.page_size())
     |> stream(:profiles, profiles)}
  end

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
        <div class="mb-8">
          <h1 class="text-4xl font-bold text-base-content mb-2">Kurator</h1>
          <p class="text-base-content/60 text-lg">
            Temukan para profesional pengelola dan kurator koleksi
          </p>
        </div>

        <%!-- Search & filter bar --%>
        <div class="flex flex-col sm:flex-row gap-3 mb-6">
          <div class="relative flex-1">
            <.icon
              name="hero-magnifying-glass"
              class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-base-content/40"
            />
            <input
              id="profile-search"
              type="text"
              name="q"
              value={@search}
              placeholder="Cari kurator berdasarkan nama, keahlian, atau kota..."
              class="input input-bordered w-full pl-10"
              phx-change="search"
              phx-debounce="300"
            />
          </div>

          <div class="flex gap-2 flex-wrap">
            <%= for {label, val} <- @institution_type_options do %>
              <button
                phx-click="filter_type"
                phx-value-type={val || ""}
                class={[
                  "btn btn-sm",
                  @institution_type == val && "btn-primary",
                  @institution_type != val && "btn-ghost border border-base-300"
                ]}
              >
                {label}
              </button>
            <% end %>
          </div>
        </div>

        <%!-- Results grid --%>
        <div
          id="profiles"
          class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5"
          phx-update="stream"
        >
          <div :for={{id, profile} <- @streams.profiles} id={id}>
            <.profile_card profile={profile} />
          </div>
        </div>

        <%!-- Empty state --%>
        <div
          :if={@streams.profiles == %{} or map_size(@streams.profiles) == 0}
          class="hidden only:block text-center py-20 text-base-content/40"
        >
          <.icon name="hero-user-group" class="w-16 h-16 mx-auto mb-4 opacity-30" />
          <p class="text-lg font-medium">Belum ada kurator ditemukan</p>
          <p class="text-sm">Coba ubah kata kunci pencarian</p>
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

  defp profile_card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow border border-base-300 hover:shadow-xl hover:-translate-y-0.5 transition-all duration-300 overflow-hidden">
      <%!-- Cover image --%>
      <div class="h-24 overflow-hidden">
        <%= if @profile.cover_url do %>
          <img src={asset_url(@profile.cover_url)} alt="" class="w-full h-full object-cover" />
        <% else %>
          <div class="w-full h-full bg-gradient-to-br from-violet-400 to-purple-600"></div>
        <% end %>
      </div>

      <div class="card-body pt-0 -mt-8">
        <%!-- Avatar --%>
        <div class="w-16 h-16 rounded-full ring-4 ring-base-100 overflow-hidden bg-violet-200 dark:bg-violet-800 flex items-center justify-center">
          <%= if @profile.avatar_url do %>
            <img
              src={asset_url(@profile.avatar_url)}
              alt={@profile.display_name}
              class="w-full h-full object-cover"
            />
          <% else %>
            <span class="text-2xl font-bold text-violet-600 dark:text-violet-300">
              {String.first(@profile.display_name || "K")}
            </span>
          <% end %>
        </div>

        <div class="mt-1">
          <div class="flex items-center gap-1.5">
            <h3 class="font-bold text-base leading-tight line-clamp-1">{@profile.display_name}</h3>
            <.icon
              :if={@profile.is_verified}
              name="hero-check-badge"
              class="w-4 h-4 text-primary shrink-0"
            />
          </div>
          <p class="text-xs text-base-content/50">@{@profile.username}</p>
        </div>

        <p :if={@profile.headline} class="text-sm text-base-content/70 line-clamp-2 leading-snug">
          {@profile.headline}
        </p>

        <p
          :if={@profile.city}
          class="text-xs text-base-content/50 flex items-center gap-1"
        >
          <.icon name="hero-map-pin-micro" class="w-3 h-3 shrink-0" />
          <span class="truncate">
            {@profile.city}
            <%= if @profile.province do %>
              , {@profile.province}
            <% end %>
          </span>
        </p>

        <div class="flex gap-3 text-xs text-base-content/50">
          <span>{@profile.follower_count} pengikut</span>
          <%= if @profile.institution_type do %>
            <span class="badge badge-xs badge-outline capitalize">{@profile.institution_type}</span>
          <% end %>
        </div>

        <div class="card-actions mt-2">
          <.link
            navigate={~p"/u/#{@profile.username}"}
            class="btn btn-sm btn-outline btn-primary w-full"
          >
            Lihat Profil
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
