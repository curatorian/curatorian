defmodule CuratorianWeb.Public.Events.IndexLive do
  @moduledoc "Public event board listing (/events)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @event_type_options [
    {"Semua", nil},
    {"Webinar", "webinar"},
    {"Seminar", "seminar"},
    {"Workshop", "workshop"},
    {"Pameran", "exhibition"},
    {"Konferensi", "conference"},
    {"Pelatihan", "training"},
    {"Lainnya", "other"}
  ]

  @mode_options [
    {"Semua", nil},
    {"Online", "online"},
    {"Offline", "offline"},
    {"Hybrid", "hybrid"}
  ]

  @category_options [
    {"Semua", nil},
    {"Perpustakaan", "library"},
    {"Arsip", "archives"},
    {"Museum", "museum"},
    {"Galeri", "gallery"},
    {"Pendidikan", "education"},
    {"Penelitian", "research"},
    {"Teknologi", "technology"},
    {"Lainnya", "other"}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Event GLAM Indonesia")
     |> assign(:search, "")
     |> assign(:event_type, nil)
     |> assign(:mode, nil)
     |> assign(:category, nil)
     |> assign(:starts_at_after, nil)
     |> assign(:page, 1)
     |> assign(:events_count, 0)
     |> assign(:event_type_options, @event_type_options)
     |> assign(:mode_options, @mode_options)
     |> assign(:category_options, @category_options)}
  end

  def handle_params(params, _uri, socket) do
    q = Map.get(params, "q", "")
    event_type = Map.get(params, "event_type", nil)
    mode = Map.get(params, "mode", nil)
    category = Map.get(params, "category", nil)
    starts_at_after = Map.get(params, "starts_at_after", nil)
    page = String.to_integer(Map.get(params, "page", "1"))

    events =
      Public.list_events(
        q,
        event_type: event_type,
        mode: mode,
        category: category,
        starts_at_after: starts_at_after,
        page: page
      )

    {:noreply,
     socket
     |> assign(:search, q)
     |> assign(:event_type, event_type)
     |> assign(:mode, mode)
     |> assign(:category, category)
     |> assign(:starts_at_after, starts_at_after)
     |> assign(:page, page)
     |> assign(:events_count, length(events))
     |> assign(:has_more, length(events) == Public.page_size())
     |> stream(:events, events, reset: true)}
  end

  def handle_event("search", %{"q" => q}, socket) do
    params =
      build_params(
        q,
        socket.assigns.event_type,
        socket.assigns.mode,
        socket.assigns.category,
        socket.assigns.starts_at_after,
        1
      )

    {:noreply, push_patch(socket, to: ~p"/events?#{params}")}
  end

  def handle_event(
        "filter",
        %{
          "event_type" => event_type,
          "mode" => mode,
          "category" => category,
          "starts_at_after" => starts_at_after
        },
        socket
      ) do
    event_type = if(event_type == "", do: nil, else: event_type)
    mode = if(mode == "", do: nil, else: mode)
    category = if(category == "", do: nil, else: category)
    starts_at_after = if(starts_at_after == "", do: nil, else: starts_at_after)

    params = build_params(socket.assigns.search, event_type, mode, category, starts_at_after, 1)
    {:noreply, push_patch(socket, to: ~p"/events?#{params}")}
  end

  def handle_event("load_more", _, socket) do
    next_page = socket.assigns.page + 1

    events =
      Public.list_events(
        socket.assigns.search,
        event_type: socket.assigns.event_type,
        mode: socket.assigns.mode,
        category: socket.assigns.category,
        starts_at_after: socket.assigns.starts_at_after,
        page: next_page
      )

    updated_count = socket.assigns.events_count + length(events)

    {:noreply,
     socket
     |> assign(:page, next_page)
     |> assign(:events_count, updated_count)
     |> assign(:has_more, length(events) == Public.page_size())
     |> stream(:events, events)}
  end

  defp build_params(search, event_type, mode, category, starts_at_after, page) do
    %{}
    |> then(fn map -> if(search != "", do: Map.put(map, "q", search), else: map) end)
    |> then(fn map -> if(event_type, do: Map.put(map, "event_type", event_type), else: map) end)
    |> then(fn map -> if(mode, do: Map.put(map, "mode", mode), else: map) end)
    |> then(fn map -> if(category, do: Map.put(map, "category", category), else: map) end)
    |> then(fn map ->
      if(starts_at_after, do: Map.put(map, "starts_at_after", starts_at_after), else: map)
    end)
    |> then(fn map -> if(page > 1, do: Map.put(map, "page", to_string(page)), else: map) end)
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto py-8 px-4">
        <div class="mb-8">
          <h1 class="text-3xl sm:text-4xl font-semibold text-base-content mb-2">
            Event GLAM Indonesia
          </h1>
          <p class="text-base text-base-content/60">
            Temukan seminar, workshop, pameran, dan event komunitas lainnya
          </p>
        </div>

        <form phx-change="filter" class="grid grid-cols-1 lg:grid-cols-5 gap-3 mb-6">
          <div class="lg:col-span-2">
            <input
              type="text"
              name="q"
              value={@search}
              placeholder="Cari judul, deskripsi, atau kota..."
              class="w-full border border-base-300 rounded-xl px-4 py-2 text-sm focus:border-primary focus:outline-none"
              phx-debounce="300"
              phx-keyup="search"
            />
          </div>

          <div>
            <select
              name="event_type"
              class="w-full border border-base-300 rounded-xl px-3 py-2 text-sm"
            >
              <%= for {label, val} <- @event_type_options do %>
                <option value={val || ""} selected={@event_type == val}>{label}</option>
              <% end %>
            </select>
          </div>

          <div>
            <select name="mode" class="w-full border border-base-300 rounded-xl px-3 py-2 text-sm">
              <%= for {label, val} <- @mode_options do %>
                <option value={val || ""} selected={@mode == val}>{label}</option>
              <% end %>
            </select>
          </div>

          <div>
            <select name="category" class="w-full border border-base-300 rounded-xl px-3 py-2 text-sm">
              <%= for {label, val} <- @category_options do %>
                <option value={val || ""} selected={@category == val}>{label}</option>
              <% end %>
            </select>
          </div>

          <div>
            <input
              type="date"
              name="starts_at_after"
              value={@starts_at_after || ""}
              class="w-full border border-base-300 rounded-xl px-3 py-2 text-sm"
            />
          </div>
        </form>

        <div id="events" phx-update="stream" class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div :for={{id, event} <- @streams.events} id={id}>
            <article class="bg-base-100 border border-base-300 rounded-2xl p-4 hover:shadow-lg transition">
              <div class="mb-3">
                <p class="text-xs uppercase tracking-widest text-base-content/60 mb-2">
                  {event_badge(event)}
                </p>
                <.link
                  class="text-xl font-semibold text-primary hover:text-primary-content"
                  navigate={"/events/#{event.slug}"}
                >
                  {event.title}
                </.link>
              </div>
              <p class="text-sm text-base-content/80 line-clamp-3 whitespace-pre-line">
                {event.description || "-"}
              </p>
              <div class="mt-3 text-sm text-base-content/70 space-y-1">
                <p>📍 {venue_text(event)}</p>
                <p>🕒 {date_range(event)}</p>
                <p>👥 {registration_text(event)}</p>
              </div>
            </article>
          </div>
        </div>

        <div
          :if={@events_count == 0}
          class="p-10 border border-base-300 rounded-2xl text-center text-base-content/70"
        >
          Belum ada event terjadwal saat ini. Cek lagi nanti.
        </div>

        <div :if={@has_more} class="flex justify-center mt-8">
          <button
            phx-click="load_more"
            class="px-6 py-2 rounded-full border border-primary text-primary hover:bg-primary hover:text-primary-content transition"
          >
            Muat lebih banyak
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp event_badge(event) do
    [to_label(event.event_type), to_label(event.mode), to_label(event.category)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" • ")
  end

  defp venue_text(event) do
    cond do
      event.mode == :online -> "Online"
      event.venue_city && event.venue_province -> "#{event.venue_city}, #{event.venue_province}"
      event.venue_city -> event.venue_city
      true -> "-"
    end
  end

  defp date_range(event) do
    starts = event.starts_at && DateTime.to_date(event.starts_at) |> Date.to_string()
    ends = event.ends_at && DateTime.to_date(event.ends_at) |> Date.to_string()

    if starts && ends, do: "#{starts} – #{ends}", else: "Tanggal belum tersedia"
  end

  defp registration_text(event) do
    count = event.registration_count || 0
    max = event.max_attendees

    cond do
      max && max > 0 -> "#{count}/#{max} terdaftar"
      true -> "#{count} terdaftar"
    end
  end

  defp to_label(:webinar), do: "Webinar"
  defp to_label(:seminar), do: "Seminar"
  defp to_label(:workshop), do: "Workshop"
  defp to_label(:exhibition), do: "Pameran"
  defp to_label(:conference), do: "Konferensi"
  defp to_label(:training), do: "Pelatihan"
  defp to_label(:other), do: "Lainnya"
  defp to_label(:online), do: "Online"
  defp to_label(:offline), do: "Offline"
  defp to_label(:hybrid), do: "Hybrid"
  defp to_label(_), do: ""
end
