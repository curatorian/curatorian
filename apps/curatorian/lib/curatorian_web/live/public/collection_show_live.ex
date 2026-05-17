defmodule CuratorianWeb.Public.CollectionShowLive do
  @moduledoc "Public collection detail page (/collections/:id)."

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

        personal_library_node =
          if collection.unit do
            Public.get_node_profile_by_voile_node(collection.unit.id)
          end

        current_user = socket.assigns.current_scope && socket.assigns.current_scope.user
        current_user_node = Map.get(current_user || %{}, :node_id)

        is_personal_library =
          personal_library_node && personal_library_node.node_type == :personal

        can_request_borrow =
          is_personal_library && current_user && current_user_node != collection.unit.id

        is_personal_library_owner =
          is_personal_library && current_user_node == collection.unit.id

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
         |> assign(:org_profile_id, org_profile_id)
         |> assign(:can_request_borrow, can_request_borrow)
         |> assign(:is_personal_library_owner, is_personal_library_owner)
         |> assign(:og_title, collection.title)
         |> assign(:og_description, collection.description)
         |> assign(:og_image, collection.thumbnail && asset_url(collection.thumbnail))
         |> assign(:og_url, "/collections/#{collection.id}")
         |> assign(:og_type, "website")
         |> assign(:twitter_card, if(collection.thumbnail, do: "summary_large_image", else: "summary"))}
    end
  end

  def handle_event("request_borrow", %{"item-id" => item_id}, socket) do
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user

    cond do
      current_user == nil ->
        {:noreply, put_flash(socket, :error, "Please log in to request a borrow.")}

      not socket.assigns.can_request_borrow ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Borrow requests are only available for personal library collections."
         )}

      true ->
        lender_user_id =
          PersonalLibrary.get_owner_user_id_for_node(socket.assigns.collection.unit.id)

        case Enum.find(socket.assigns.collection.items, fn item ->
               to_string(item.id) == item_id
             end) do
          nil ->
            {:noreply, put_flash(socket, :error, "Item not found.")}

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
                {:noreply, put_flash(socket, :info, "Borrow request successfully created.")}

              {:error, _changeset} ->
                {:noreply, put_flash(socket, :error, "Failed to create borrow request.")}
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
              <div class="mb-4">
                <%= if @is_personal_library_owner do %>
                  <.link
                    navigate={~p"/personal/borrow-reviews"}
                    class="btn btn-sm btn-outline"
                  >
                    {gettext("Review borrow requests")}
                  </.link>
                <% else %>
                  <%= if @can_request_borrow do %>
                    <p class="text-sm text-base-content/70">
                      {gettext("Choose an item below and click Request to send a borrow request.")}
                    </p>
                  <% end %>
                <% end %>
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
                <div class="space-y-5">
                  <div>
                    <h2 class="text-base font-semibold">Data Item</h2>
                    <p class="mt-2 text-sm text-base-content/60">
                      Daftar item dalam koleksi berikut ketersediaan dan statusnya.
                    </p>
                  </div>

                  <div class="grid gap-4 sm:grid-cols-2">
                    <div class="rounded-3xl border border-base-300/70 bg-base-200 p-4">
                      <p class="text-xs uppercase tracking-wide text-base-content/50">
                        Total item
                      </p>
                      <p class="mt-2 text-3xl font-semibold text-base-content">
                        {@item_summary.total_items}
                      </p>
                    </div>

                    <div class="rounded-3xl border border-base-300/70 bg-base-200 p-4">
                      <p class="text-xs uppercase tracking-wide text-base-content/50">
                        Ketersediaan
                      </p>
                      <div class="mt-3 grid gap-2">
                        <%= for {status, count} <- @item_summary.availability_summary do %>
                          <div class="flex items-center justify-between gap-3 rounded-3xl bg-base-100 px-3 py-2 text-sm">
                            <span class="text-base-content">{status}</span>
                            <span class="font-semibold text-base-content">{count}</span>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </div>

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
                              <p class="text-xs uppercase tracking-wide text-base-content/50">
                                Barcode
                              </p>
                              <p class="mt-1 font-medium text-base-content break-words whitespace-normal">
                                {item.barcode || item.inventory_code || item.item_code || "-"}
                              </p>
                            </div>
                            <span class="rounded-full bg-base-200 px-3 py-1 text-xs font-semibold text-base-content shrink-0">
                              {item.availability || "Unknown"}
                            </span>
                          </div>

                          <div class="mt-4 grid gap-3 text-sm text-base-content/70">
                            <div class="grid gap-1">
                              <span class="font-semibold text-base-content">Status</span>
                              <span>{item.status || "-"}</span>
                            </div>
                            <div class="grid gap-1">
                              <span class="font-semibold text-base-content">Lokasi</span>
                              <span>{item.location || "-"}</span>
                            </div>
                          </div>

                          <div class="mt-4 text-xs text-base-content/50">
                            {gettext("Item ID")}: {item.id}
                          </div>

                          <div class="mt-5">
                            <%= if @can_request_borrow do %>
                              <button
                                phx-click="request_borrow"
                                phx-value-item-id={item.id}
                                class="btn btn-sm btn-primary w-full"
                              >
                                {gettext("Request")}
                              </button>
                            <% else %>
                              <div class="rounded-3xl border border-base-300/70 bg-base-200 p-3 text-center text-xs text-base-content/50">
                                {if(@current_scope && @current_scope.user,
                                  do: gettext("Request unavailable"),
                                  else: gettext("Log in to request")
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
