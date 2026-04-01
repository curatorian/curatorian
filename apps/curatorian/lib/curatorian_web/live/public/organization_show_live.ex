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

      %{profile: profile, node: node, org_page: org_page} ->
        merged = org_page || profile

        org = %{
          id: profile.id,
          voile_node_id: profile.voile_node_id,
          name: Map.get(merged, :name) || profile.institution_name || Map.get(node, :name) || "",
          abbr: Map.get(node, :abbr) || "",
          node_image: Public.asset_url(Map.get(node, :image)),
          institution_type: Map.get(merged, :institution_type) || profile.institution_type,
          node_type: Map.get(merged, :node_type) || profile.node_type,
          tagline: Map.get(merged, :tagline),
          description: Map.get(merged, :description),
          category: Map.get(merged, :category),
          institution_size: Map.get(merged, :institution_size),
          avatar_url:
            Public.asset_url(Map.get(merged, :avatar_url) || Map.get(profile, :avatar_url)),
          cover_url:
            Public.asset_url(Map.get(merged, :cover_url) || Map.get(profile, :cover_url)),
          website: Map.get(merged, :website) || Map.get(profile, :website),
          email: Map.get(merged, :email) || Map.get(profile, :email),
          phone: Map.get(merged, :phone) || Map.get(profile, :phone),
          whatsapp: Map.get(merged, :whatsapp) || Map.get(profile, :whatsapp),
          address: Map.get(merged, :address) || Map.get(profile, :address),
          city: Map.get(merged, :city) || Map.get(profile, :city),
          province: Map.get(merged, :province) || Map.get(profile, :province),
          social_links: Map.get(merged, :social_links) || Map.get(profile, :social_links) || %{},
          is_public:
            Map.get(merged, :is_public)
            |> then(fn x -> if(is_nil(x), do: Map.get(profile, :is_public), else: x) end),
          is_verified:
            Map.get(merged, :is_verified)
            |> then(fn x -> if(is_nil(x), do: Map.get(profile, :is_verified), else: x) end),
          type_label:
            Map.get(
              @institution_type_labels,
              Map.get(merged, :institution_type) || profile.institution_type,
              nil
            )
        }

        collection_count = Public.count_collections_for_node(profile.voile_node_id)

        {:noreply,
         socket
         |> assign(:page_title, org.name)
         |> assign(:org, org)
         |> assign(:active_tab, "info")
         |> assign(:collection_count, collection_count)
         |> assign(:collections_page, 1)
         |> assign(:collections_loaded, false)
         |> assign(:has_more_collections, false)
         |> assign(:staff_loaded, false)
         |> assign(:staff_members, [])
         |> stream(:collections, [])}
    end
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    socket =
      cond do
        tab == "collections" ->
          collections =
            Public.list_collections_for_node(socket.assigns.org.voile_node_id, page: 1)

          socket
          |> assign(:collections_loaded, true)
          |> assign(:collections_page, 1)
          |> assign(:has_more_collections, length(collections) == Public.page_size())
          |> stream(:collections, collections, reset: true)

        tab == "staff" and not socket.assigns.staff_loaded ->
          staff_members = Public.list_staff_for_node(socket.assigns.org.voile_node_id)

          socket
          |> assign(:staff_loaded, true)
          |> assign(:staff_members, staff_members)

        true ->
          socket
      end

    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("load_more_collections", _, socket) do
    next_page = socket.assigns.collections_page + 1

    collections =
      Public.list_collections_for_node(socket.assigns.org.voile_node_id, page: next_page)

    {:noreply,
     socket
     |> assign(:collections_page, next_page)
     |> assign(:has_more_collections, length(collections) == Public.page_size())
     |> stream(:collections, collections)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto pb-16 animate-fade-in">
        <%!-- ── Back navigation ─────────────────────────────────────────────── --%>
        <div class="mb-5">
          <.link
            navigate={~p"/orgs"}
            class="inline-flex items-center gap-1.5 text-sm font-medium text-base-content/50 hover:text-primary transition-colors duration-150 group"
          >
            <.icon
              name="hero-arrow-left"
              class="size-4 transition-transform duration-150 group-hover:-translate-x-0.5"
            /> Kembali ke daftar organisasi
          </.link>
        </div>

        <%!-- ── Hero cover ───────────────────────────────────────────────────── --%>
        <div class="relative rounded-3xl overflow-hidden h-56 md:h-72 shadow-inner">
          <%= if @org.node_image do %>
            <img
              src={@org.node_image}
              alt={@org.name}
              class="absolute inset-0 w-full h-full object-cover"
            />
          <% else %>
            <div class="absolute inset-0 bg-gradient-to-br from-primary via-secondary to-accent">
            </div>
          <% end %>
          <div class="absolute inset-0 bg-gradient-to-t from-black/75 via-black/20 to-transparent">
          </div>
          <div class="absolute inset-0 flex items-center justify-center">
            <span class="text-base-content/20 text-5xl font-black tracking-widest">
              {String.upcase(@org.name || "ORGANISASI")}
            </span>
          </div>
        </div>

        <%!-- ── Identity block — overlaps cover ─────────────────────────────── --%>
        <div class="relative -mt-16 px-4 mb-6 animate-slide-in-left">
          <div class="bg-base-100/95 backdrop-blur-xl rounded-3xl border border-base-300 p-5 shadow-lg grid grid-cols-1 sm:grid-cols-[auto_1fr] gap-4 items-center">
            <%!-- Logo / avatar --%>
            <div class="w-24 h-24 md:w-28 md:h-28 rounded-2xl overflow-hidden border border-base-300 bg-base-200 flex items-center justify-center shadow-inner">
              <%= if @org.node_image do %>
                <img src={@org.node_image} alt={@org.name} class="w-full h-full object-cover" />
              <% else %>
                <span class="text-4xl font-bold text-primary/70">
                  {String.first(@org.name || "O")}
                </span>
              <% end %>
            </div>

            <%!-- Name & metadata --%>
            <div class="min-w-0">
              <p class="text-2xl md:text-3xl font-bold text-base-content leading-tight line-clamp-1">
                {@org.name}
              </p>
              <p :if={@org.abbr} class="text-sm text-base-content/50 mt-0.5 font-mono">
                {@org.abbr}
              </p>

              <div class="mt-3 flex flex-wrap items-center gap-2">
                <span
                  :if={@org.type_label}
                  class="text-xs font-semibold uppercase bg-primary/15 text-primary px-2.5 py-1 rounded-full"
                >
                  {@org.type_label}
                </span>
                <span :if={@org.city} class="text-xs text-base-content/60 flex items-center gap-1">
                  <.icon name="hero-map-pin-micro" class="size-3" />{@org.city}{if @org.province,
                    do: ", #{@org.province}"}
                </span>
              </div>
            </div>
          </div>
        </div>

        <%!-- ── Tab bar ─────────────────────────────────────────────────────── --%>
        <div class="flex border-b border-base-300 mb-6 gap-1">
          <button
            phx-click="switch_tab"
            phx-value-tab="info"
            class={[
              "flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition-all duration-150",
              @active_tab == "info" &&
                "border-primary text-primary",
              @active_tab != "info" &&
                "border-transparent text-base-content/50 hover:text-base-content hover:border-base-300"
            ]}
          >
            <.icon name="hero-information-circle" class="size-4" /> Informasi
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="collections"
            class={[
              "flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition-all duration-150",
              @active_tab == "collections" &&
                "border-primary text-primary",
              @active_tab != "collections" &&
                "border-transparent text-base-content/50 hover:text-base-content hover:border-base-300"
            ]}
          >
            <.icon name="hero-rectangle-stack" class="size-4" /> Koleksi
            <span
              :if={@collection_count > 0}
              class="text-xs bg-base-300 text-base-content/60 px-1.5 py-0.5 rounded-full tabular-nums leading-none"
            >
              {@collection_count}
            </span>
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="staff"
            class={[
              "flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition-all duration-150",
              @active_tab == "staff" &&
                "border-primary text-primary",
              @active_tab != "staff" &&
                "border-transparent text-base-content/50 hover:text-base-content hover:border-base-300"
            ]}
          >
            <.icon name="hero-user-group" class="size-4" /> Anggota
          </button>
        </div>

        <%!-- ── Tab: Informasi ─────────────────────────────────────────────── --%>
        <div :if={@active_tab == "info"} class="grid grid-cols-1 md:grid-cols-3 gap-5">
          <%!-- Main column: summary --%>
          <div class="md:col-span-2 space-y-4">
            <section class="bg-base-100 rounded-2xl border border-base-300 p-5 shadow-sm">
              <div class="flex items-center gap-2">
                <h2 class="text-xl font-semibold">{gettext("Tentang Organisasi")}</h2>
                <span class={[
                  "px-2 py-1 rounded-full text-xs font-medium",
                  @org.is_verified == true && "bg-success text-success-content",
                  @org.is_verified != true && "bg-base-200 text-base-content/70"
                ]}>
                  {if @org.is_verified == true,
                    do: gettext("Terverifikasi"),
                    else: gettext("Belum terverifikasi")}
                </span>
              </div>
              <p class="text-sm text-base-content/70 mt-2">
                {@org.tagline || gettext("Tidak ada gambaran singkat")}
              </p>
              <p class="text-sm text-base-content/80 mt-3">
                {@org.description || gettext("Deskripsi organisasi belum tersedia.")}
              </p>
              <div class="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div class="rounded-lg bg-base-200 p-3">
                  <span class="text-xs text-base-content/50">{gettext("Kategori")}</span>
                  <p class="font-semibold text-base-content">{@org.category || "-"}</p>
                </div>
                <div class="rounded-lg bg-base-200 p-3">
                  <span class="text-xs text-base-content/50">{gettext("Ukuran")}</span>
                  <p class="font-semibold text-base-content">{@org.institution_size || "-"}</p>
                </div>
                <div class="rounded-lg bg-base-200 p-3">
                  <span class="text-xs text-base-content/50">{gettext("Tipe")}</span>
                  <p class="font-semibold text-base-content">{@org.type_label || "-"}</p>
                </div>
                <div class="rounded-lg bg-base-200 p-3">
                  <span class="text-xs text-base-content/50">{gettext("Alamat")}</span>
                  <p class="font-semibold text-base-content">
                    {[@org.address, @org.city, @org.province]
                    |> Enum.reject(fn value -> value in [nil, ""] end)
                    |> Enum.join(", ")
                    |> then(fn v -> if v == "", do: "-", else: v end)}
                  </p>
                </div>
              </div>
            </section>

            <section class="bg-base-100 rounded-2xl border border-base-300 p-5 hover:shadow-sm transition-shadow duration-200">
              <p class="text-[10px] font-bold uppercase tracking-widest text-base-content/40 mb-3 flex items-center gap-1.5">
                <.icon name="hero-map-pin" class="size-3.5 text-primary" /> Lokasi & Alamat
              </p>
              <p class="text-sm text-base-content/80 leading-relaxed">{@org.address}</p>
              <p :if={@org.city} class="text-xs text-base-content/50 mt-1.5">
                {@org.city}
                <%= if @org.province do %>
                  , {@org.province}
                <% end %>
              </p>
            </section>

            <%!-- Empty state when no info at all --%>
            <section
              :if={!@org.address and !@org.website and !@org.phone}
              class="bg-base-100 rounded-2xl border border-base-300 border-dashed p-12 flex flex-col items-center text-center"
            >
              <div class="size-12 rounded-2xl bg-base-200 flex items-center justify-center mb-3">
                <.icon name="hero-building-office-2" class="size-6 text-base-content/20" />
              </div>
              <p class="text-sm font-medium text-base-content/40">Informasi belum tersedia</p>
              <p class="text-xs text-base-content/30 mt-1">
                Detail organisasi ini belum dilengkapi
              </p>
            </section>
          </div>

          <%!-- Sidebar: contact --%>
          <div class="space-y-4">
            <section class="bg-base-100 rounded-2xl border border-base-300 p-5">
              <p class="text-[10px] font-bold uppercase tracking-widest text-base-content/40 mb-3">
                Kontak
              </p>
              <div class="space-y-3">
                <a
                  :if={@org.website}
                  href={@org.website}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="flex items-start gap-2.5 text-sm text-primary transition-opacity hover:opacity-75"
                >
                  <.icon name="hero-globe-alt" class="size-4 shrink-0 mt-0.5 text-base-content/30" />
                  <span class="break-all leading-relaxed">{@org.website}</span>
                </a>
                <span
                  :if={@org.email}
                  class="flex items-center gap-2.5 text-sm text-base-content/70"
                >
                  <.icon name="hero-envelope" class="size-4 shrink-0 text-base-content/30" />
                  {@org.email}
                </span>
                <span
                  :if={@org.phone}
                  class="flex items-center gap-2.5 text-sm text-base-content/70"
                >
                  <.icon name="hero-phone" class="size-4 shrink-0 text-base-content/30" />
                  {@org.phone}
                </span>
                <span
                  :if={@org.whatsapp}
                  class="flex items-center gap-2.5 text-sm text-base-content/70"
                >
                  <.icon
                    name="hero-chat-bubble-left-right"
                    class="size-4 shrink-0 text-base-content/30"
                  />
                  {@org.whatsapp}
                </span>
                <div
                  :if={map_size(@org.social_links || %{}) > 0}
                  class="pt-2 border-t border-base-200"
                >
                  <p class="text-[10px] font-bold uppercase tracking-widest text-base-content/40 mb-2">
                    {gettext("Sosial media")}
                  </p>
                  <ul class="space-y-1 text-xs">
                    <li :for={{platform, url} <- @org.social_links}>
                      <a
                        href={url}
                        target="_blank"
                        rel="noopener noreferrer"
                        class="text-primary hover:text-primary-content"
                      >
                        {String.capitalize(to_string(platform))}: {String.replace_prefix(
                          url,
                          "https://",
                          ""
                        )}
                      </a>
                    </li>
                  </ul>
                </div>
                <p
                  :if={!@org.website and !@org.phone}
                  class="text-sm text-base-content/35 italic"
                >
                  Tidak ada kontak tersedia
                </p>
              </div>
            </section>
          </div>
        </div>

        <%!-- ── Tab: Koleksi ──────────────────────────────────────────────── --%>
        <div :if={@active_tab == "collections"}>
          <%!-- Empty state --%>
          <div
            :if={@collection_count == 0}
            class="py-20 flex flex-col items-center text-center"
          >
            <div class="size-16 rounded-3xl bg-base-200 flex items-center justify-center mb-4">
              <.icon name="hero-rectangle-stack" class="size-8 text-base-content/20" />
            </div>
            <p class="font-medium text-base-content/40">Belum ada koleksi publik</p>
            <p class="text-xs text-base-content/30 mt-1">
              Organisasi ini belum mempublikasikan koleksi
            </p>
          </div>

          <%!-- Collection grid --%>
          <div
            :if={@collection_count > 0}
            id="org-collections"
            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
            phx-update="stream"
          >
            <div :for={{id, col} <- @streams.collections} id={id}>
              <.collection_card col={col} />
            </div>
          </div>

          <%!-- Load more --%>
          <div :if={@has_more_collections} class="flex justify-center mt-8">
            <button
              phx-click="load_more_collections"
              class="inline-flex items-center gap-2 px-8 py-2.5 rounded-full border border-primary/50 text-primary text-sm font-medium hover:bg-primary hover:text-primary-content transition-all duration-200"
            >
              <.icon name="hero-arrow-down" class="size-4" /> Muat lebih banyak
            </button>
          </div>
        </div>

        <%!-- ── Tab: Tim ───────────────────────────────────────────────────── --%>
        <div :if={@active_tab == "staff"}>
          <%!-- Empty state --%>
          <div
            :if={@staff_loaded and @staff_members == []}
            class="py-20 flex flex-col items-center text-center"
          >
            <div class="size-16 rounded-3xl bg-base-200 flex items-center justify-center mb-4">
              <.icon name="hero-user-group" class="size-8 text-base-content/20" />
            </div>
            <p class="font-medium text-base-content/40">Belum ada anggota tim</p>
            <p class="text-xs text-base-content/30 mt-1">
              Organisasi ini belum mendaftarkan tim publik
            </p>
          </div>

          <%!-- Loading skeleton --%>
          <div
            :if={@staff_loaded != true}
            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
          >
            <div
              :for={_i <- 1..6}
              class="bg-base-200 rounded-2xl h-28 animate-shimmer"
            >
            </div>
          </div>

          <%!-- Staff grid --%>
          <div
            :if={@staff_loaded and @staff_members != []}
            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
          >
            <.staff_card :for={member <- @staff_members} member={member} />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp collection_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/collections/#{@col.id}"}
      class="group block bg-base-100 rounded-2xl border border-base-300/70 hover:border-primary/30 shadow-sm hover:shadow-md hover:-translate-y-0.5 transition-all duration-300 overflow-hidden"
    >
      <figure class="h-36 overflow-hidden bg-gradient-to-br from-primary/10 to-accent/15">
        <%= if @col.thumbnail do %>
          <img
            src={asset_url(@col.thumbnail)}
            alt={@col.title}
            class="w-full h-full object-cover"
          />
        <% else %>
          <div class="w-full h-full flex items-center justify-center">
            <.icon name="hero-rectangle-stack" class="size-10 text-primary/25" />
          </div>
        <% end %>
      </figure>
      <div class="p-4 space-y-1.5">
        <p class="font-semibold text-sm leading-snug line-clamp-2 text-base-content group-hover:text-primary transition-colors duration-150">
          {@col.title}
        </p>
        <p :if={@col.description} class="text-xs text-base-content/55 line-clamp-2 leading-relaxed">
          {@col.description}
        </p>
        <p :if={@col.collection_code} class="text-xs font-mono text-base-content/35">
          {@col.collection_code}
        </p>
      </div>
    </.link>
    """
  end

  defp role_label(role) when is_binary(role) do
    case String.downcase(role) do
      "super_admin" -> "Super Admin"
      "super admin" -> "Super Admin"
      "admin" -> "Admin"
      "administrator" -> "Admin"
      "curatorian administrator" -> "Admin"
      "manager" -> "Manager"
      "staff" -> "Manager"
      "viewer" -> "Viewer"
      other -> other
    end
  end

  defp role_label(_), do: "Viewer"

  defp role_badge_class(role) when is_binary(role) do
    case String.downcase(role) do
      "super_admin" -> "bg-secondary/15 text-secondary border border-secondary/30"
      "super admin" -> "bg-secondary/15 text-secondary border border-secondary/30"
      "admin" -> "bg-secondary/10 text-secondary border border-secondary/20"
      "administrator" -> "bg-secondary/10 text-secondary border border-secondary/20"
      "curatorian administrator" -> "bg-secondary/10 text-secondary border border-secondary/20"
      "manager" -> "bg-primary/10 text-primary border border-primary/20"
      "staff" -> "bg-primary/10 text-primary border border-primary/20"
      "viewer" -> "bg-base-300 text-base-content/50 border border-base-300"
      _ -> "bg-base-300 text-base-content/50 border border-base-300"
    end
  end

  defp role_badge_class(_), do: "bg-base-300 text-base-content/50 border border-base-300"

  defp staff_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/u/#{@member.username}"}
      class="group flex items-start gap-4 bg-base-100 rounded-2xl border border-base-300/70 hover:border-primary/30 p-4 shadow-sm hover:shadow-md hover:-translate-y-0.5 transition-all duration-300"
    >
      <%!-- Avatar --%>
      <div class="size-12 rounded-xl shrink-0 overflow-hidden bg-gradient-to-br from-primary/20 to-accent/30 flex items-center justify-center ring-1 ring-base-300">
        <%= if @member.avatar_url do %>
          <img
            src={Public.asset_url(@member.avatar_url)}
            alt={@member.display_name}
            class="w-full h-full object-cover"
          />
        <% else %>
          <span class="text-lg font-bold text-primary/60">
            {String.first(@member.display_name || @member.username || "?")}
          </span>
        <% end %>
      </div>

      <%!-- Info --%>
      <div class="min-w-0 flex-1">
        <div class="flex items-start justify-between gap-2 mb-0.5">
          <p class="font-semibold text-sm text-base-content group-hover:text-primary transition-colors duration-150 truncate leading-snug">
            {@member.display_name || @member.username}
          </p>
          <span class={[
            "shrink-0 text-[10px] font-semibold uppercase tracking-wide px-2 py-0.5 rounded-full",
            role_badge_class(@member.role_name)
          ]}>
            {role_label(@member.role_name)}
          </span>
        </div>
        <p :if={@member.headline} class="text-xs text-base-content/55 line-clamp-1 leading-relaxed">
          {@member.headline}
        </p>
        <p :if={@member.city} class="flex items-center gap-1 text-xs text-base-content/35 mt-1">
          <.icon name="hero-map-pin-micro" class="size-3 shrink-0" />
          {@member.city}
          <%= if @member.province do %>
            , {@member.province}
          <% end %>
        </p>
      </div>
    </.link>
    """
  end
end
