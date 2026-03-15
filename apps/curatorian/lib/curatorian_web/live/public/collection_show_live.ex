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
        {:noreply,
         socket
         |> assign(:page_title, collection.title)
         |> assign(:collection, collection)
         |> assign(:type_label, Map.get(@type_labels, collection.collection_type, nil))}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto pb-12 px-4">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8 mt-4">
          <%!-- Left: thumbnail --%>
          <div class="md:col-span-1">
            <div class="aspect-[3/4] rounded-2xl overflow-hidden shadow-xl border border-base-300 bg-gradient-to-br from-violet-100 to-purple-200 dark:from-violet-900 dark:to-purple-800">
              <%= if @collection.thumbnail do %>
                <img
                  src={asset_url(@collection.thumbnail)}
                  alt={@collection.title}
                  class="w-full h-full object-cover"
                />
              <% else %>
                <div class="w-full h-full flex flex-col items-center justify-center gap-4 p-6">
                  <.icon
                    name="hero-rectangle-stack"
                    class="w-20 h-20 text-violet-300 dark:text-violet-500"
                  />
                  <p class="text-xs text-base-content/40 text-center font-medium">
                    Tidak ada thumbnail
                  </p>
                </div>
              <% end %>
            </div>
          </div>

          <%!-- Right: details --%>
          <div class="md:col-span-2 space-y-5">
            <%!-- Title & badges --%>
            <div>
              <div class="flex items-start gap-2 flex-wrap mb-2">
                <span :if={@type_label} class="badge badge-secondary">{@type_label}</span>
                <span class="badge badge-outline badge-sm text-emerald-600 border-emerald-400">
                  Dipublikasikan
                </span>
              </div>
              <h1 class="text-2xl md:text-3xl font-bold leading-tight">{@collection.title}</h1>
              <p
                :if={@collection.collection_code}
                class="text-xs font-mono text-base-content/40 mt-1"
              >
                Kode: {@collection.collection_code}
              </p>
            </div>

            <%!-- Unit / institution --%>
            <div
              :if={@collection.unit}
              class="flex items-center gap-3 p-4 rounded-xl border border-base-300 bg-base-100"
            >
              <div class="w-10 h-10 rounded-lg overflow-hidden bg-emerald-100 dark:bg-emerald-900 flex items-center justify-center shrink-0">
                <%= if @collection.unit.image do %>
                  <img
                    src={asset_url(@collection.unit.image)}
                    alt={@collection.unit.name}
                    class="w-full h-full object-cover"
                  />
                <% else %>
                  <.icon name="hero-building-library" class="w-5 h-5 text-emerald-600" />
                <% end %>
              </div>
              <div class="min-w-0">
                <p class="text-xs text-base-content/50 uppercase tracking-wide font-semibold">
                  Institusi
                </p>
                <p class="font-semibold text-sm truncate">{@collection.unit.name}</p>
                <p
                  :if={@collection.unit.abbr}
                  class="text-xs text-base-content/50"
                >
                  {@collection.unit.abbr}
                </p>
              </div>
            </div>

            <%!-- Description --%>
            <div
              :if={@collection.description}
              class="card bg-base-100 border border-base-300 shadow-sm"
            >
              <div class="card-body">
                <h2 class="card-title text-base">Deskripsi</h2>
                <p class="text-base-content/80 whitespace-pre-line text-sm leading-relaxed">
                  {@collection.description}
                </p>
              </div>
            </div>

            <%!-- Metadata row --%>
            <div class="grid grid-cols-2 gap-3">
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

            <%!-- Back link --%>
            <.link
              navigate={~p"/collections"}
              class="btn btn-sm btn-ghost text-base-content/60 hover:text-base-content"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> Kembali ke daftar koleksi
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
