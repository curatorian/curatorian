defmodule CuratorianWeb.Public.CollectionShowLive do
  @moduledoc "Public collection detail page (/collections/:id)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @type_labels %{
    "book" => "Buku",
    "series" => "Seri",
    "movie" => "Film",
    "album" => "Album",
    "course" => "Kursus",
    "other" => "Lainnya"
  }

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    case Public.get_public_collection(id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Koleksi tidak ditemukan.")
         |> push_navigate(to: ~p"/collections")}

      collection ->
        org_profile_id =
          if collection.unit do
            Public.get_node_profile_id_by_voile_node(collection.unit.id)
          end

        collection_fields =
          collection.collection_fields
          |> Enum.sort_by(&(&1.sort_order || 0))

        {:noreply,
         socket
         |> assign(:page_title, collection.title)
         |> assign(:collection, collection)
         |> assign(:collection_fields, collection_fields)
         |> assign(:item_summary, build_item_summary(collection))
         |> assign(:type_label, Map.get(@type_labels, collection.collection_type, nil))
         |> assign(:org_profile_id, org_profile_id)}
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

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto pb-16 px-4 sm:px-6 lg:px-8">
        <div class="grid gap-8 lg:grid-cols-[minmax(320px,360px)_minmax(0,1fr)] items-start">
          <%!-- Left: thumbnail + organization --%>
          <div class="space-y-5">
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
                    <.icon
                      name="hero-rectangle-stack"
                      class="w-20 h-20 text-primary/30"
                    />
                    <p class="text-sm text-base-content/50 font-medium">
                      Thumbnail tidak tersedia
                    </p>
                  </div>
                <% end %>
              </div>
            </div>

            <div class="rounded-[2rem] border border-base-300/70 bg-base-100 shadow-sm p-5">
              <p class="text-xs uppercase tracking-wide text-base-content/50 mb-3">
                Organisasi pemilik koleksi
              </p>
              <%= if @collection.unit do %>
                <div class="flex items-center gap-4">
                  <div class="flex h-14 w-14 items-center justify-center rounded-3xl bg-primary/10 text-primary">
                    <%= if @collection.unit.image do %>
                      <img
                        src={asset_url(@collection.unit.image)}
                        alt={@collection.unit.name}
                        class="h-full w-full rounded-3xl object-cover"
                      />
                    <% else %>
                      <.icon name="hero-building-library" class="w-6 h-6" />
                    <% end %>
                  </div>
                  <div class="min-w-0">
                    <p class="text-sm font-semibold text-base-content line-clamp-2">
                      {@collection.unit.name}
                    </p>
                    <p class="text-sm text-base-content/60">
                      {if @collection.unit.abbr, do: @collection.unit.abbr}
                    </p>
                  </div>
                </div>
              <% else %>
                <p class="text-sm text-base-content/60">Informasi organisasi tidak tersedia.</p>
              <% end %>
            </div>
          </div>

          <%!-- Right: details --%>
          <div class="space-y-6">
            <div class="rounded-[2rem] border border-base-300/70 bg-base-100 shadow-xl p-6">
              <div class="flex flex-wrap items-center gap-3 mb-4">
                <span
                  :if={@type_label}
                  class="inline-flex rounded-full border border-primary/20 bg-primary/10 px-3 py-1 text-xs font-semibold uppercase text-primary"
                >
                  {@type_label}
                </span>
                <span class="inline-flex rounded-full border border-success/20 bg-success/10 px-3 py-1 text-xs font-semibold uppercase text-success">
                  Dipublikasikan
                </span>
              </div>

              <h1 class="text-3xl sm:text-4xl font-semibold tracking-tight text-base-content">
                {@collection.title}
              </h1>

              <p
                :if={@collection.collection_code}
                class="mt-3 text-sm font-medium text-base-content/60"
              >
                Kode koleksi: {@collection.collection_code}
              </p>
            </div>

            <div class="rounded-[2rem] border border-base-300/70 bg-base-100 shadow-sm p-6">
              <h2 class="text-base font-semibold">Deskripsi</h2>
              <p class="mt-4 text-sm leading-7 text-base-content/80 whitespace-pre-line">
                {@collection.description || "Tidak ada deskripsi koleksi."}
              </p>
            </div>

            <div class="space-y-5">
              <div class="rounded-[2rem] border border-base-300/70 bg-base-100 shadow-sm p-6">
                <h2 class="text-base font-semibold">Metadata Koleksi</h2>
                <div class="mt-4 space-y-4 text-sm">
                  <%= if @collection_fields != [] do %>
                    <div class="grid gap-4">
                      <%= for field <- @collection_fields do %>
                        <div class="grid gap-3 sm:grid-cols-[160px_1fr]">
                          <span class="text-xs uppercase tracking-wide text-base-content/50">
                            {field.label || field.name}
                          </span>
                          <span class="text-sm text-base-content break-words">
                            {field.value}
                          </span>
                        </div>
                      <% end %>
                    </div>
                  <% else %>
                    <p class="text-sm text-base-content/60">
                      Metadata koleksi tidak tersedia.
                    </p>
                  <% end %>
                </div>
              </div>

              <div class="rounded-[2rem] border border-base-300/70 bg-base-100 shadow-sm p-6">
                <div class="flex flex-col gap-4">
                  <div>
                    <h2 class="text-base font-semibold">Data Item</h2>
                    <p class="mt-2 text-sm text-base-content/60">
                      Daftar item dalam koleksi berikut ketersediaan dan statusnya.
                    </p>
                  </div>

                  <div class="rounded-3xl bg-base-200 p-4">
                    <p class="text-xs uppercase tracking-wide text-base-content/50">Total item</p>
                    <p class="mt-2 text-3xl font-semibold text-base-content">
                      {@item_summary.total_items}
                    </p>
                  </div>

                  <div>
                    <p class="text-xs uppercase tracking-wide text-base-content/50 mb-3">
                      Ketersediaan
                    </p>
                    <%= if @item_summary.total_items > 0 do %>
                      <div class="grid gap-3">
                        <%= for {status, count} <- @item_summary.availability_summary do %>
                          <div class="flex items-center justify-between gap-3 rounded-3xl border border-base-300/60 bg-base-200 px-4 py-3">
                            <span class="text-sm text-base-content">{status}</span>
                            <span class="text-sm font-semibold text-base-content">{count}</span>
                          </div>
                        <% end %>
                      </div>
                    <% else %>
                      <p class="text-sm text-base-content/60">
                        Belum ada item dalam koleksi ini.
                      </p>
                    <% end %>
                  </div>

                  <%= if @collection.items != [] do %>
                    <div class="overflow-x-auto rounded-[1.5rem] border border-base-300/70 bg-base-100 shadow-sm">
                      <table class="min-w-full text-sm text-left text-base-content">
                        <thead class="bg-base-200 text-xs uppercase text-base-content/50">
                          <tr>
                            <th class="px-4 py-3">Item Code</th>
                            <th class="px-4 py-3">Inventory</th>
                            <th class="px-4 py-3">Availability</th>
                            <th class="px-4 py-3">Status</th>
                            <th class="px-4 py-3">Lokasi</th>
                          </tr>
                        </thead>
                        <tbody class="divide-y divide-base-200">
                          <%= for item <- @collection.items do %>
                            <tr class="hover:bg-base-200/80 transition-colors duration-150">
                              <td class="px-4 py-3 font-medium text-base-content">
                                {item.item_code || "-"}
                              </td>
                              <td class="px-4 py-3 text-base-content/70">
                                {item.inventory_code || "-"}
                              </td>
                              <td class="px-4 py-3 text-base-content/70">
                                {item.availability || "Unknown"}
                              </td>
                              <td class="px-4 py-3 text-base-content/70">
                                {item.status || "-"}
                              </td>
                              <td class="px-4 py-3 text-base-content/70">
                                {item.location || "-"}
                              </td>
                            </tr>
                          <% end %>
                        </tbody>
                      </table>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <%!-- Metadata row --%>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div
                :if={@collection.inserted_at}
                class="rounded-xl border border-base-300 bg-base-100 p-3"
              >
                <p class="text-xs text-base-content/50 uppercase tracking-wide font-semibold mb-1">
                  Dibuat
                </p>
                <p class="text-sm font-medium">
                  {Calendar.strftime(@collection.inserted_at, "%d %b %Y")}
                </p>
              </div>

              <div
                :if={@collection.updated_at && @collection.updated_at != @collection.inserted_at}
                class="rounded-xl border border-base-300 bg-base-100 p-3"
              >
                <p class="text-xs text-base-content/50 uppercase tracking-wide font-semibold mb-1">
                  Diperbarui
                </p>
                <p class="text-sm font-medium">
                  {Calendar.strftime(@collection.updated_at, "%d %b %Y")}
                </p>
              </div>
            </div>

            <%!-- Back links --%>
            <div class="flex flex-col sm:flex-row sm:items-center sm:gap-3 gap-2">
              <.link
                navigate={~p"/collections"}
                class="btn btn-sm btn-ghost text-base-content/60 hover:text-base-content"
              >
                <.icon name="hero-arrow-left" class="w-4 h-4" /> Kembali ke daftar koleksi
              </.link>

              <.link
                :if={@org_profile_id}
                navigate={~p"/orgs/#{@org_profile_id}"}
                class="btn btn-sm btn-secondary text-base-100 hover:bg-secondary-focus"
              >
                <.icon name="hero-rectangle-stack" class="w-4 h-4" /> Kembali ke koleksi organisasi
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
