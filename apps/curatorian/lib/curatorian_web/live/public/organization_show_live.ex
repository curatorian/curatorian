defmodule CuratorianWeb.Public.OrganizationShowLive do
  @moduledoc "Public organization detail page (/orgs/:id)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @institution_type_labels %{
    library: "Perpustakaan",
    museum: "Museum",
    gallery: "Galeri",
    archive: "Arsip"
  }

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"slug" => id}, _uri, socket) do
    case Public.get_node_profile(id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Organisasi tidak ditemukan.")
         |> push_navigate(to: ~p"/orgs")}

      %{profile: profile, node: node} ->
        org = %{
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
          address: profile.address,
          type_label: Map.get(@institution_type_labels, profile.institution_type, nil)
        }

        {:noreply,
         socket
         |> assign(:page_title, org.name)
         |> assign(:org, org)}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto pb-12 px-4">
        <%!-- Cover placeholder --%>
        <div class="relative -mx-4 -mt-8 mb-0 h-48 md:h-64 overflow-hidden">
          <div class="w-full h-full bg-gradient-to-br from-emerald-400 via-teal-500 to-cyan-600">
          </div>
          <div class="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent"></div>
        </div>

        <%!-- Org header --%>
        <div class="relative -mt-16 px-4 pb-4">
          <div class="flex flex-col sm:flex-row sm:items-end gap-4">
            <%!-- Logo / avatar --%>
            <div class="w-28 h-28 rounded-2xl ring-4 ring-base-100 overflow-hidden bg-emerald-200 dark:bg-emerald-800 flex items-center justify-center shrink-0">
              <%= if @org.node_image do %>
                <img src={@org.node_image} alt={@org.name} class="w-full h-full object-cover" />
              <% else %>
                <span class="text-4xl font-bold text-emerald-700 dark:text-emerald-300">
                  {String.first(@org.name || "O")}
                </span>
              <% end %>
            </div>

            <%!-- Name & meta --%>
            <div class="pb-1 min-w-0">
              <h1 class="text-2xl md:text-3xl font-bold leading-tight">{@org.name}</h1>
              <p :if={@org.abbr} class="text-base-content/50 text-sm mt-0.5">{@org.abbr}</p>
              <div class="flex items-center gap-2 flex-wrap mt-1">
                <span :if={@org.type_label} class="badge badge-outline">
                  {@org.type_label}
                </span>
              </div>
            </div>
          </div>

          <%!-- Location row --%>
          <div :if={@org.city} class="flex flex-wrap gap-6 mt-4 text-sm text-base-content/60">
            <span class="flex items-center gap-1">
              <.icon name="hero-map-pin" class="w-4 h-4" />
              {@org.city}
              <%= if @org.province do %>
                , {@org.province}
              <% end %>
            </span>
          </div>
        </div>

        <%!-- Main content grid --%>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-4 px-4">
          <%!-- Left: address --%>
          <div class="md:col-span-2 space-y-6">
            <div :if={@org.address} class="card bg-base-100 border border-base-300 shadow-sm">
              <div class="card-body py-4">
                <h2 class="card-title text-base flex items-center gap-2">
                  <.icon name="hero-map-pin" class="w-5 h-5 text-primary" /> Lokasi
                </h2>
                <p class="text-sm text-base-content/80 leading-relaxed">{@org.address}</p>
                <p :if={@org.city} class="text-sm text-base-content/60">
                  {@org.city}
                  <%= if @org.province do %>
                    , {@org.province}
                  <% end %>
                </p>
              </div>
            </div>
          </div>

          <%!-- Right: contact --%>
          <div class="space-y-4">
            <div class="card bg-base-100 border border-base-300 shadow-sm">
              <div class="card-body py-4 gap-3">
                <h2 class="font-semibold text-sm text-base-content/60 uppercase tracking-wide">
                  Kontak
                </h2>

                <a
                  :if={@org.website}
                  href={@org.website}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="flex items-center gap-2 text-sm text-primary hover:underline"
                >
                  <.icon name="hero-globe-alt" class="w-4 h-4 shrink-0" />
                  <span class="truncate">{@org.website}</span>
                </a>

                <span :if={@org.phone} class="flex items-center gap-2 text-sm text-base-content/80">
                  <.icon name="hero-phone" class="w-4 h-4 shrink-0" />
                  {@org.phone}
                </span>
              </div>
            </div>

            <%!-- Back link --%>
            <.link
              navigate={~p"/orgs"}
              class="btn btn-sm btn-ghost w-full text-base-content/60 hover:text-base-content"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> Kembali ke daftar organisasi
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
