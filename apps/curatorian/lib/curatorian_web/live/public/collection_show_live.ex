defmodule CuratorianWeb.Public.CollectionShowLive do
  @moduledoc """
  Flagship public collection detail page (/collections/:id).

  Distinct from an organization's own collection view: this page is centred on
  the collection itself and prominently surfaces the cross-node relationship —
  which organization/node owns it, its institution type and location, and other
  collections from the same institution.
  """

  use CuratorianWeb, :live_view

  alias Curatorian.Public
  alias Curatorian.PersonalLibrary

  @type_labels %{
    "book" => "Buku",
    "series" => "Seri",
    "movie" => "Film",
    "album" => "Album",
    "course" => "Kursus",
    "other" => "Lainnya"
  }

  @glam_meta %{
    "Library" => %{
      label: "Perpustakaan",
      icon: "hero-book-open",
      badge: "bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/20"
    },
    "Museum" => %{
      label: "Museum",
      icon: "hero-building-storefront",
      badge: "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20"
    },
    "Archive" => %{
      label: "Arsip",
      icon: "hero-archive-box",
      badge: "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20"
    },
    "Gallery" => %{
      label: "Galeri",
      icon: "hero-photo",
      badge: "bg-pink-500/10 text-pink-600 dark:text-pink-400 border-pink-500/20"
    }
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    case Public.get_public_collection(id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Koleksi tidak ditemukan.")
         |> push_navigate(to: ~p"/collections")}

      collection ->
        org_context =
          if collection.unit, do: Public.get_org_context_for_node(collection.unit.id), else: nil

        related = Public.list_related_collections(collection, limit: 4)

        glam_type = collection.resource_class && collection.resource_class.glam_type

        current_user = socket.assigns.current_scope && socket.assigns.current_scope.user
        current_user_node = Map.get(current_user || %{}, :node_id)

        node_profile = org_context && org_context.node_profile
        is_personal_library = node_profile && node_profile.node_type == :personal

        can_request_borrow =
          is_personal_library && current_user && current_user_node != collection.unit.id

        is_personal_library_owner = is_personal_library && current_user_node == collection.unit.id

        collection_fields =
          collection.collection_fields
          |> Enum.reject(fn f -> is_nil(f.value) or f.value == "" end)
          |> Enum.sort_by(&(&1.sort_order || 0))

        {:noreply,
         socket
         |> assign(:page_title, collection.title)
         |> assign(:collection, collection)
         |> assign(:collection_fields, collection_fields)
         |> assign(:item_summary, build_item_summary(collection))
         |> assign(:type_label, Map.get(@type_labels, collection.collection_type, nil))
         |> assign(:glam_type, glam_type)
         |> assign(:glam_meta, glam_type && Map.get(@glam_meta, glam_type))
         |> assign(:org_context, org_context)
         |> assign(:related, related)
         |> assign(:can_request_borrow, can_request_borrow)
         |> assign(:is_personal_library_owner, is_personal_library_owner)
         |> assign(:og_title, collection.title)
         |> assign(:og_description, collection.description)
         |> assign(:og_image, collection.thumbnail && asset_url(collection.thumbnail))
         |> assign(:og_url, "/collections/#{collection.id}")
         |> assign(:og_type, "website")
         |> assign(
           :twitter_card,
           if(collection.thumbnail, do: "summary_large_image", else: "summary")
         )}
    end
  end

  @impl true
  def handle_event("request_borrow", %{"item-id" => item_id}, socket) do
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user

    cond do
      current_user == nil ->
        {:noreply, put_flash(socket, :error, "Silakan masuk untuk mengajukan permintaan pinjam.")}

      not socket.assigns.can_request_borrow ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Permintaan pinjam hanya tersedia untuk koleksi perpustakaan pribadi."
         )}

      true ->
        lender_user_id =
          PersonalLibrary.get_owner_user_id_for_node(socket.assigns.collection.unit.id)

        case Enum.find(socket.assigns.collection.items, fn item ->
               to_string(item.id) == item_id
             end) do
          nil ->
            {:noreply, put_flash(socket, :error, "Item tidak ditemukan.")}

          item ->
            attrs = %{
              "lender_user_id" => lender_user_id,
              "borrower_user_id" => current_user.id,
              "voile_item_id" => item.id,
              "item_title" => item.item_code || item.inventory_code || "",
              "status" => "pending",
              "request_message" => "Borrow request from Curatorian user"
            }

            case PersonalLibrary.create_borrow_request(attrs) do
              {:ok, _request} ->
                {:noreply, put_flash(socket, :info, "Permintaan pinjam berhasil dibuat.")}

              {:error, _changeset} ->
                {:noreply, put_flash(socket, :error, "Gagal membuat permintaan pinjam.")}
            end
        end
    end
  end

  defp build_item_summary(collection) do
    items = collection.items || []

    availability_summary =
      items
      |> Enum.frequencies_by(&(&1.availability || "unknown"))
      |> Enum.map(fn {status, count} -> {availability_label(status), count} end)
      |> Enum.sort_by(fn {_status, count} -> -count end)

    %{
      total_items: length(items),
      availability_summary: availability_summary
    }
  end

  defp availability_label(status) do
    status
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp org_link_path(%{org_context: %{org_page: %{slug: slug}}}) when not is_nil(slug),
    do: ~p"/orgs/#{slug}"

  defp org_link_path(_assigns), do: nil

  defp location_string(%{city: city, province: province}) do
    [city, province]
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(", ")
  end

  defp location_string(_), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto pb-16 px-4 sm:px-6 lg:px-8 pt-6">
        <%!-- Breadcrumbs --%>
        <nav class="flex items-center flex-wrap gap-1.5 text-xs text-base-content/50 mb-6">
          <.link navigate={~p"/"} class="hover:text-primary transition-colors">Beranda</.link>
          <.icon name="hero-chevron-right" class="size-3" />
          <.link navigate={~p"/collections"} class="hover:text-primary transition-colors">
            Koleksi
          </.link>
          <%= if @org_context && @org_context.org_page do %>
            <.icon name="hero-chevron-right" class="size-3" />
            <.link
              navigate={~p"/orgs/#{@org_context.org_page.slug}"}
              class="hover:text-primary transition-colors truncate max-w-[12rem]"
            >
              {@org_context.org_page.name || @org_context.org_page.slug}
            </.link>
          <% end %>
          <.icon name="hero-chevron-right" class="size-3" />
          <span class="text-base-content/70 truncate max-w-[16rem]">{@collection.title}</span>
        </nav>

        <div class="grid gap-8 lg:grid-cols-[minmax(300px,380px)_minmax(0,1fr)] items-start">
          <%!-- Left: thumbnail + belongs-to card --%>
          <div class="space-y-5 lg:sticky lg:top-24">
            <div class="overflow-hidden rounded-[2rem] border border-base-300/70 bg-base-100 shadow-xl">
              <div class="aspect-[4/5] bg-gradient-to-br from-primary/10 to-accent/15">
                <%= if @collection.thumbnail do %>
                  <img
                    src={asset_url(@collection.thumbnail)}
                    alt={@collection.title}
                    class="w-full h-full object-cover"
                  />
                <% else %>
                  <div class="flex h-full w-full flex-col items-center justify-center gap-4 p-6 text-center">
                    <.icon name="hero-rectangle-stack" class="w-20 h-20 text-primary/30" />
                    <p class="text-sm text-base-content/50 font-medium">Thumbnail tidak tersedia</p>
                  </div>
                <% end %>
              </div>
            </div>

            <%!-- Belongs-to relationship card (the cross-node link) --%>
            <div class="rounded-[2rem] border border-base-300/70 bg-base-100 shadow-sm p-5">
              <div class="flex items-center justify-between mb-3">
                <p class="text-xs uppercase tracking-wide text-base-content/50 font-semibold">
                  Institusi pemilik
                </p>
                <.icon name="hero-link" class="size-4 text-base-content/30" />
              </div>

              <%= if @org_context && @org_context.unit do %>
                <div class="flex items-start gap-3">
                  <div class="flex size-12 items-center justify-center rounded-2xl bg-primary/10 text-primary shrink-0 overflow-hidden">
                    <%= if @org_context.unit.image do %>
                      <img
                        src={asset_url(@org_context.unit.image)}
                        alt={@org_context.unit.name}
                        class="h-full w-full object-cover"
                      />
                    <% else %>
                      <.icon name="hero-building-library" class="w-6 h-6" />
                    <% end %>
                  </div>
                  <div class="min-w-0 flex-1">
                    <div class="flex items-center gap-1.5">
                      <p class="text-sm font-semibold text-base-content line-clamp-2">
                        {@org_context.unit.name}
                      </p>
                      <%= if @org_context.org_page && @org_context.org_page.is_verified do %>
                        <.icon name="hero-check-badge" class="size-4 text-primary shrink-0" />
                      <% end %>
                    </div>

                    <div class="mt-1 flex flex-wrap gap-1.5">
                      <%= if @glam_meta do %>
                        <span class={[
                          "inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[10px] font-semibold",
                          @glam_meta.badge
                        ]}>
                          <.icon name={@glam_meta.icon} class="size-2.5" />
                          {@glam_meta.label}
                        </span>
                      <% end %>
                      <%= if @org_context.node_profile && @org_context.node_profile.institution_type do %>
                        <span class="inline-flex rounded-full border border-base-300 bg-base-200 px-2 py-0.5 text-[10px] font-medium text-base-content/60">
                          {institution_humanize(@org_context.node_profile.institution_type)}
                        </span>
                      <% end %>
                    </div>

                    <%= if loc = @org_context.node_profile && location_string(@org_context.node_profile) do %>
                      <p class="mt-1.5 text-xs text-base-content/50 flex items-center gap-1">
                        <.icon name="hero-map-pin" class="size-3 shrink-0" />
                        {loc}
                      </p>
                    <% end %>
                  </div>
                </div>

                <%= if org_link_path(assigns) do %>
                  <.link
                    navigate={org_link_path(assigns)}
                    class="mt-4 flex items-center justify-center gap-1.5 w-full py-2 rounded-xl text-xs font-semibold text-primary border border-primary/30 hover:bg-primary hover:text-primary-content transition-all duration-200"
                  >
                    <.icon name="hero-building-office-2" class="size-3.5" /> Lihat profil institusi
                  </.link>
                <% end %>
              <% else %>
                <p class="text-sm text-base-content/60">Informasi institusi tidak tersedia.</p>
              <% end %>
            </div>
          </div>

          <%!-- Right: details --%>
          <div class="space-y-6 min-w-0">
            <%!-- Title block --%>
            <div class="rounded-[2rem] border border-base-300/70 bg-base-100 shadow-xl p-6 sm:p-7">
              <div class="flex flex-wrap items-center gap-2 mb-4">
                <%= if @glam_meta do %>
                  <span class={[
                    "inline-flex items-center gap-1 rounded-full border px-3 py-1 text-xs font-semibold",
                    @glam_meta.badge
                  ]}>
                    <.icon name={@glam_meta.icon} class="size-3.5" />
                    {@glam_meta.label}
                  </span>
                <% end %>
                <span
                  :if={@type_label}
                  class="inline-flex rounded-full border border-base-300 bg-base-200 px-3 py-1 text-xs font-medium text-base-content/70"
                >
                  {@type_label}
                </span>
                <span class="inline-flex items-center gap-1 rounded-full border border-success/20 bg-success/10 px-3 py-1 text-xs font-semibold text-success">
                  <.icon name="hero-check-circle" class="size-3.5" /> Dipublikasikan
                </span>
              </div>

              <h1 class="text-2xl sm:text-3xl lg:text-4xl font-semibold tracking-tight text-base-content leading-tight">
                {@collection.title}
              </h1>

              <%= if @collection.collection_code do %>
                <p class="mt-3 text-xs font-mono text-base-content/50 flex items-center gap-1.5">
                  <.icon name="hero-qr-code" class="size-3.5" />
                  {@collection.collection_code}
                </p>
              <% end %>

              <%= if @is_personal_library_owner do %>
                <div class="mt-5">
                  <.link navigate={~p"/personal/borrow-reviews"} class="btn btn-sm btn-outline">
                    Tinjau permintaan pinjam
                  </.link>
                </div>
              <% else %>
                <p
                  :if={@can_request_borrow}
                  class="mt-5 text-sm text-base-content/70 bg-info/10 border border-info/20 rounded-xl p-3"
                >
                  Pilih item di bawah dan klik <strong>Pinjam</strong> untuk mengajukan permintaan.
                </p>
              <% end %>
            </div>

            <%!-- Description --%>
            <div class="rounded-[2rem] border border-base-300/70 bg-base-100 shadow-sm p-6">
              <h2 class="text-base font-semibold flex items-center gap-2">
                <.icon name="hero-document-text" class="size-4 text-base-content/50" /> Deskripsi
              </h2>
              <p class="mt-3 text-sm leading-7 text-base-content/80 whitespace-pre-line">
                {@collection.description || "Tidak ada deskripsi koleksi."}
              </p>
            </div>

            <%!-- Metadata (Dublin Core) --%>
            <div class="rounded-[2rem] border border-base-300/70 bg-base-100 shadow-sm p-6">
              <h2 class="text-base font-semibold flex items-center gap-2">
                <.icon name="hero-information-circle" class="size-4 text-base-content/50" />
                Metadata Koleksi
              </h2>
              <%= if @collection_fields != [] do %>
                <dl class="mt-4 grid gap-x-6 gap-y-3 sm:grid-cols-[160px_1fr]">
                  <%= for field <- @collection_fields do %>
                    <dt class="text-xs uppercase tracking-wide text-base-content/50 font-semibold pt-0.5">
                      {field.label || field.name}
                    </dt>
                    <dd class="text-sm text-base-content break-words">{field.value}</dd>
                  <% end %>
                </dl>
              <% else %>
                <p class="mt-3 text-sm text-base-content/60">Metadata koleksi tidak tersedia.</p>
              <% end %>
            </div>

            <%!-- Items --%>
            <div class="rounded-[2rem] border border-base-300/70 bg-base-100 shadow-sm p-6">
              <div class="space-y-5">
                <div class="flex items-end justify-between gap-4">
                  <div>
                    <h2 class="text-base font-semibold flex items-center gap-2">
                      <.icon name="hero-cube" class="size-4 text-base-content/50" />
                      Item dalam Koleksi
                    </h2>
                    <p class="mt-1 text-sm text-base-content/60">
                      Daftar item beserta ketersediaan dan statusnya.
                    </p>
                  </div>
                  <span class="text-2xl font-semibold text-base-content shrink-0">
                    {@item_summary.total_items}
                  </span>
                </div>

                <%= if @item_summary.availability_summary != [] do %>
                  <div class="flex flex-wrap gap-2">
                    <%= for {status, count} <- @item_summary.availability_summary do %>
                      <span class="inline-flex items-center gap-1.5 rounded-full bg-base-200 px-3 py-1 text-xs text-base-content/70">
                        <span class="size-1.5 rounded-full bg-primary"></span>
                        {status}
                        <span class="font-semibold text-base-content">{count}</span>
                      </span>
                    <% end %>
                  </div>
                <% end %>

                <%= if @collection.items == [] do %>
                  <div class="rounded-3xl border border-base-300/70 bg-base-200 p-4 text-sm text-base-content/70">
                    Belum ada item dalam koleksi ini.
                  </div>
                <% else %>
                  <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
                    <%= for item <- @collection.items do %>
                      <div class="rounded-[1.5rem] border border-base-300/70 bg-base-100 p-4 shadow-sm flex flex-col">
                        <div class="flex items-start justify-between gap-4">
                          <div class="min-w-0">
                            <p class="text-[10px] uppercase tracking-wide text-base-content/50">
                              Barcode
                            </p>
                            <p class="mt-1 font-medium text-sm text-base-content break-words">
                              {item.barcode || item.inventory_code || item.item_code || "-"}
                            </p>
                          </div>
                          <span class="rounded-full bg-base-200 px-3 py-1 text-[11px] font-semibold text-base-content shrink-0">
                            {item.availability || "Unknown"}
                          </span>
                        </div>

                        <div class="mt-4 grid gap-2 text-sm text-base-content/70">
                          <div class="grid gap-0.5">
                            <span class="text-[11px] font-semibold uppercase tracking-wide text-base-content/50">
                              Status
                            </span>
                            <span>{item.status || "-"}</span>
                          </div>
                          <div class="grid gap-0.5">
                            <span class="text-[11px] font-semibold uppercase tracking-wide text-base-content/50">
                              Lokasi
                            </span>
                            <span>{item.location || "-"}</span>
                          </div>
                        </div>

                        <div class="mt-4">
                          <%= if @can_request_borrow do %>
                            <button
                              phx-click="request_borrow"
                              phx-value-item-id={item.id}
                              class="btn btn-sm btn-primary w-full"
                            >
                              Pinjam
                            </button>
                          <% else %>
                            <div class="rounded-3xl border border-base-300/70 bg-base-200 p-2.5 text-center text-[11px] text-base-content/50">
                              {if(@current_scope && @current_scope.user,
                                do: "Tidak tersedia",
                                else: "Masuk untuk meminjam"
                              )}
                            </div>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>

            <%!-- Related collections (same organization) --%>
            <%= if @related != [] do %>
              <div class="rounded-[2rem] border border-base-300/70 bg-base-100 shadow-sm p-6">
                <div class="flex items-center justify-between gap-4 mb-4">
                  <h2 class="text-base font-semibold flex items-center gap-2">
                    <.icon name="hero-squares-2x2" class="size-4 text-base-content/50" />
                    Koleksi lain dari institusi ini
                  </h2>
                  <%= if org_link_path(assigns) do %>
                    <.link
                      navigate={org_link_path(assigns)}
                      class="text-xs text-primary hover:underline whitespace-nowrap"
                    >
                      Lihat semua
                    </.link>
                  <% end %>
                </div>

                <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                  <.link
                    :for={col <- @related}
                    navigate={~p"/collections/#{col.id}"}
                    class="group rounded-2xl border border-base-300/70 bg-base-100 overflow-hidden hover:shadow-md hover:-translate-y-0.5 transition-all duration-300"
                  >
                    <div class="h-24 overflow-hidden bg-gradient-to-br from-primary/10 to-accent/15">
                      <%= if col.thumbnail do %>
                        <img
                          src={asset_url(col.thumbnail)}
                          alt={col.title}
                          class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                          loading="lazy"
                        />
                      <% else %>
                        <div class="w-full h-full flex items-center justify-center">
                          <.icon name="hero-rectangle-stack" class="size-7 text-primary/30" />
                        </div>
                      <% end %>
                    </div>
                    <p class="p-2.5 text-xs font-medium text-base-content line-clamp-2 leading-snug">
                      {col.title}
                    </p>
                  </.link>
                </div>
              </div>
            <% end %>

            <%!-- Back links --%>
            <div class="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-3">
              <.link
                navigate={~p"/collections"}
                class="btn btn-sm btn-ghost text-base-content/60 hover:text-base-content"
              >
                <.icon name="hero-arrow-left" class="w-4 h-4" /> Kembali ke pencarian koleksi
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp institution_humanize(type) when is_atom(type),
    do: type |> Atom.to_string() |> institution_humanize()

  defp institution_humanize(type) when is_binary(type) do
    %{
      "library" => "Perpustakaan",
      "museum" => "Museum",
      "gallery" => "Galeri",
      "archive" => "Arsip"
    }
    |> Map.get(type, type)
  end

  defp institution_humanize(other), do: other
end
