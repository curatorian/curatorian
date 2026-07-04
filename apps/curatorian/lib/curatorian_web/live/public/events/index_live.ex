defmodule CuratorianWeb.Public.Events.IndexLive do
  @moduledoc "Enhanced public event board listing (/events)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @event_type_options [
    {"Semua Jenis", nil},
    {"Webinar", "webinar"},
    {"Seminar", "seminar"},
    {"Workshop", "workshop"},
    {"Pameran", "exhibition"},
    {"Konferensi", "conference"},
    {"Pelatihan", "training"},
    {"Program Baca", "reading_program"},
    {"Lainnya", "other"}
  ]

  @mode_options [
    {"Semua Mode", nil},
    {"Online", "online"},
    {"Offline", "offline"},
    {"Hybrid", "hybrid"}
  ]

  @category_options [
    {"Semua Kategori", nil},
    {"Perpustakaan", "library"},
    {"Arsip", "archives"},
    {"Museum", "museum"},
    {"Galeri", "gallery"},
    {"Pendidikan", "education"},
    {"Penelitian", "research"},
    {"Teknologi", "technology"},
    {"Lainnya", "other"}
  ]

  @time_filter_options [
    {"Semua Waktu", nil},
    {"Hari Ini", "today"},
    {"Minggu Ini", "this_week"},
    {"Bulan Ini", "this_month"},
    {"Mendatang", "upcoming"}
  ]

  @sort_options [
    {"Terbaru", "newest"},
    {"Terdekat", "soonest"},
    {"Populer", "popular"}
  ]

  def mount(_params, _session, socket) do
    current_user_id =
      if socket.assigns.current_scope && socket.assigns.current_scope.user do
        socket.assigns.current_scope.user.id
      end

    {:ok,
     socket
     |> assign(:page_title, "Event GLAM Indonesia")
     |> assign(:search, "")
     |> assign(:event_type, nil)
     |> assign(:mode, nil)
     |> assign(:category, nil)
     |> assign(:time_filter, nil)
     |> assign(:sort_by, "soonest")
     |> assign(:show_paid_only, false)
     |> assign(:page, 1)
     |> assign(:events_count, 0)
     |> assign(:current_user_id, current_user_id)
     |> assign(:event_type_options, @event_type_options)
     |> assign(:mode_options, @mode_options)
     |> assign(:category_options, @category_options)
     |> assign(:time_filter_options, @time_filter_options)
     |> assign(:sort_options, @sort_options)}
  end

  def handle_params(params, _uri, socket) do
    q = Map.get(params, "q", "")
    event_type = Map.get(params, "event_type")
    mode = Map.get(params, "mode")
    category = Map.get(params, "category")
    time_filter = Map.get(params, "time_filter")
    sort_by = Map.get(params, "sort_by", "soonest")
    show_paid_only = Map.get(params, "paid") == "true"
    page = String.to_integer(Map.get(params, "page", "1"))

    starts_at_after = compute_time_filter(time_filter)

    opts = [
      event_type: event_type,
      mode: mode,
      category: category,
      starts_at_after: starts_at_after,
      page: page
    ]

    events = Public.list_events(q, opts)
    events = maybe_filter_paid(events, show_paid_only)
    events = apply_sort(events, sort_by)

    # Check user registrations
    current_user_id = socket.assigns.current_user_id

    events_with_reg_status =
      if current_user_id do
        Enum.map(events, fn event ->
          registered = Public.check_event_registration(current_user_id, event.id)
          Map.put(event, :user_registered, registered)
        end)
      else
        Enum.map(events, &Map.put(&1, :user_registered, false))
      end

    {:noreply,
     socket
     |> assign(:search, q)
     |> assign(:event_type, event_type)
     |> assign(:mode, mode)
     |> assign(:category, category)
     |> assign(:time_filter, time_filter)
     |> assign(:sort_by, sort_by)
     |> assign(:show_paid_only, show_paid_only)
     |> assign(:page, page)
     |> assign(:events_count, length(events_with_reg_status))
     |> assign(:has_more, length(events) == Public.page_size())
     |> stream(:events, events_with_reg_status, reset: true)}
  end

  def handle_event("search", %{"q" => q}, socket) do
    params = build_params(socket, q)
    {:noreply, push_patch(socket, to: ~p"/events?#{params}")}
  end

  def handle_event("filter", params, socket) do
    event_type = normalize_param(params["event_type"])
    mode = normalize_param(params["mode"])
    category = normalize_param(params["category"])
    time_filter = normalize_param(params["time_filter"])
    sort_by = params["sort_by"] || "soonest"
    show_paid_only = params["show_paid_only"] == "true"

    updated_params =
      build_params(
        %{
          socket
          | assigns:
              Map.merge(socket.assigns, %{
                search: socket.assigns.search,
                event_type: event_type,
                mode: mode,
                category: category,
                time_filter: time_filter,
                sort_by: sort_by,
                show_paid_only: show_paid_only
              })
        },
        socket.assigns.search
      )

    {:noreply, push_patch(socket, to: ~p"/events?#{updated_params}")}
  end

  def handle_event("clear_filters", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/events")}
  end

  def handle_event("load_more", _, socket) do
    next_page = socket.assigns.page + 1
    starts_at_after = compute_time_filter(socket.assigns.time_filter)

    opts = [
      event_type: socket.assigns.event_type,
      mode: socket.assigns.mode,
      category: socket.assigns.category,
      starts_at_after: starts_at_after,
      page: next_page
    ]

    events = Public.list_events(socket.assigns.search, opts)
    events = maybe_filter_paid(events, socket.assigns.show_paid_only)
    events = apply_sort(events, socket.assigns.sort_by)

    current_user_id = socket.assigns.current_user_id

    events_with_reg_status =
      if current_user_id do
        Enum.map(events, fn event ->
          registered = Public.check_event_registration(current_user_id, event.id)
          Map.put(event, :user_registered, registered)
        end)
      else
        Enum.map(events, &Map.put(&1, :user_registered, false))
      end

    updated_count = socket.assigns.events_count + length(events_with_reg_status)

    {:noreply,
     socket
     |> assign(:page, next_page)
     |> assign(:events_count, updated_count)
     |> assign(:has_more, length(events) == Public.page_size())
     |> stream(:events, events_with_reg_status)}
  end

  defp normalize_param(""), do: nil
  defp normalize_param(nil), do: nil
  defp normalize_param(val), do: val

  defp compute_time_filter("today") do
    Date.utc_today() |> Date.to_string()
  end

  defp compute_time_filter("this_week") do
    today = Date.utc_today()
    start_of_week = Date.beginning_of_week(today)
    Date.to_string(start_of_week)
  end

  defp compute_time_filter("this_month") do
    today = Date.utc_today()
    start_of_month = %{today | day: 1}
    Date.to_string(start_of_month)
  end

  defp compute_time_filter("upcoming"), do: Date.utc_today() |> Date.to_string()
  defp compute_time_filter(_), do: nil

  defp maybe_filter_paid(events, true), do: Enum.filter(events, & &1.is_paid)
  defp maybe_filter_paid(events, _), do: events

  defp apply_sort(events, "newest") do
    Enum.sort_by(events, & &1.inserted_at, {:desc, DateTime})
  end

  defp apply_sort(events, "soonest") do
    Enum.sort_by(events, & &1.starts_at, {:asc, DateTime})
  end

  defp apply_sort(events, "popular") do
    Enum.sort_by(events, & &1.registration_count, :desc)
  end

  defp apply_sort(events, _), do: events

  defp build_params(socket, search) do
    %{}
    |> maybe_put("q", search)
    |> maybe_put("event_type", socket.assigns.event_type)
    |> maybe_put("mode", socket.assigns.mode)
    |> maybe_put("category", socket.assigns.category)
    |> maybe_put("time_filter", socket.assigns.time_filter)
    |> maybe_put("sort_by", socket.assigns.sort_by)
    |> maybe_put_bool("paid", socket.assigns.show_paid_only)
    |> maybe_put_page(socket.assigns.page)
  end

  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_bool(map, _key, false), do: map
  defp maybe_put_bool(map, key, true), do: Map.put(map, key, "true")

  defp maybe_put_page(map, page) when page > 1, do: Map.put(map, "page", to_string(page))
  defp maybe_put_page(map, _), do: map

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-7xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
        <%!-- Header --%>
        <div class="mb-8">
          <h1 class="text-3xl sm:text-4xl font-bold text-base-content mb-3 tracking-tight">
            Event GLAM Indonesia
          </h1>
          <p class="text-base sm:text-lg text-base-content/70 max-w-3xl">
            Temukan dan ikuti seminar, workshop, pameran, dan event komunitas GLAM lainnya
          </p>
        </div>

        <%!-- Search Bar --%>
        <div class="mb-6">
          <div class="relative">
            <.icon
              name="hero-magnifying-glass"
              class="absolute left-4 top-1/2 -translate-y-1/2 size-5 text-base-content/40"
            />
            <input
              type="text"
              name="q"
              value={@search}
              placeholder="Cari judul, deskripsi, lokasi..."
              class="w-full pl-12 pr-4 py-3.5 border border-base-300 rounded-2xl text-sm focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none transition bg-base-100"
              phx-debounce="300"
              phx-keyup="search"
            />
          </div>
        </div>

        <%!-- Filters --%>
        <form phx-change="filter" class="mb-8">
          <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 mb-4">
            <div>
              <label class="text-xs font-medium text-base-content/60 mb-1.5 block">Jenis Event</label>
              <select
                name="event_type"
                class="w-full border border-base-300 rounded-xl px-3 py-2.5 text-sm focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none transition bg-base-100"
              >
                <%= for {label, val} <- @event_type_options do %>
                  <option value={val || ""} selected={@event_type == val}>{label}</option>
                <% end %>
              </select>
            </div>

            <div>
              <label class="text-xs font-medium text-base-content/60 mb-1.5 block">Mode</label>
              <select
                name="mode"
                class="w-full border border-base-300 rounded-xl px-3 py-2.5 text-sm focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none transition bg-base-100"
              >
                <%= for {label, val} <- @mode_options do %>
                  <option value={val || ""} selected={@mode == val}>{label}</option>
                <% end %>
              </select>
            </div>

            <div>
              <label class="text-xs font-medium text-base-content/60 mb-1.5 block">Kategori</label>
              <select
                name="category"
                class="w-full border border-base-300 rounded-xl px-3 py-2.5 text-sm focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none transition bg-base-100"
              >
                <%= for {label, val} <- @category_options do %>
                  <option value={val || ""} selected={@category == val}>{label}</option>
                <% end %>
              </select>
            </div>

            <div>
              <label class="text-xs font-medium text-base-content/60 mb-1.5 block">Waktu</label>
              <select
                name="time_filter"
                class="w-full border border-base-300 rounded-xl px-3 py-2.5 text-sm focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none transition bg-base-100"
              >
                <%= for {label, val} <- @time_filter_options do %>
                  <option value={val || ""} selected={@time_filter == val}>{label}</option>
                <% end %>
              </select>
            </div>

            <div>
              <label class="text-xs font-medium text-base-content/60 mb-1.5 block">Urutan</label>
              <select
                name="sort_by"
                class="w-full border border-base-300 rounded-xl px-3 py-2.5 text-sm focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none transition bg-base-100"
              >
                <%= for {label, val} <- @sort_options do %>
                  <option value={val} selected={@sort_by == val}>{label}</option>
                <% end %>
              </select>
            </div>

            <div class="flex items-end">
              <label class="flex items-center gap-2 px-4 py-2.5 border border-base-300 rounded-xl cursor-pointer hover:bg-base-200/50 transition w-full">
                <input
                  type="checkbox"
                  name="show_paid_only"
                  value="true"
                  checked={@show_paid_only}
                  class="size-4 rounded border-base-300 text-primary focus:ring-primary"
                />
                <span class="text-sm font-medium text-base-content">Berbayar</span>
              </label>
            </div>
          </div>

          <button
            type="button"
            phx-click="clear_filters"
            class="text-sm text-primary hover:text-primary-focus font-medium flex items-center gap-1 transition"
          >
            <.icon name="hero-x-mark" class="size-4" /> Hapus Filter
          </button>
        </form>

        <%!-- Event Grid --%>
        <div
          id="events"
          phx-update="stream"
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
        >
          <article
            :for={{id, event} <- @streams.events}
            id={id}
            class="group bg-base-100 border border-base-300 rounded-2xl overflow-hidden hover:shadow-xl hover:border-primary/20 transition-all duration-300"
          >
            <%!-- Event Cover Image --%>
            <div class="relative aspect-video bg-gradient-to-br from-primary/10 to-secondary/10 overflow-hidden">
              <%= if event.cover_image_url do %>
                <img
                  src={event.cover_image_url}
                  alt={event.title}
                  class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                />
              <% else %>
                <div class="w-full h-full flex items-center justify-center">
                  <.icon name="hero-calendar-days" class="size-16 text-base-content/20" />
                </div>
              <% end %>

              <%!-- Status Badges --%>
              <div class="absolute top-3 left-3 flex flex-wrap gap-2">
                <%= if event.user_registered do %>
                  <span class="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-success text-success-content text-xs font-semibold shadow-lg">
                    <.icon name="hero-check-circle" class="size-3.5" /> Terdaftar
                  </span>
                <% end %>
                <%= if event.is_paid do %>
                  <span class="px-3 py-1 rounded-full bg-warning text-warning-content text-xs font-semibold shadow-lg">
                    Rp {format_idr(event.price_idr || 0)}
                  </span>
                <% else %>
                  <span class="px-3 py-1 rounded-full bg-success text-success-content text-xs font-semibold shadow-lg">
                    Gratis
                  </span>
                <% end %>
              </div>

              <%!-- Registration Status --%>
              <div class="absolute bottom-3 right-3">
                <%= cond do %>
                  <% registration_full?(event) -> %>
                    <span class="px-3 py-1 rounded-full bg-error text-error-content text-xs font-semibold shadow-lg">
                      Penuh
                    </span>
                  <% registration_closing_soon?(event) -> %>
                    <span class="px-3 py-1 rounded-full bg-warning text-warning-content text-xs font-semibold shadow-lg">
                      Segera Ditutup
                    </span>
                  <% true -> %>
                    <span class="px-3 py-1 rounded-full bg-info text-info-content text-xs font-semibold shadow-lg">
                      Tersedia
                    </span>
                <% end %>
              </div>
            </div>

            <%!-- Event Content --%>
            <div class="p-5 space-y-3">
              <%!-- Event Type & Category --%>
              <div class="flex items-center gap-2 text-xs text-base-content/60">
                <span class="font-medium">{type_label(event.event_type)}</span>
                <span>•</span>
                <span>{mode_label(event.mode)}</span>
              </div>

              <%!-- Title --%>
              <.link
                navigate={"/events/#{event.slug}"}
                class="block text-lg font-bold text-base-content group-hover:text-primary transition line-clamp-2"
              >
                {event.title}
              </.link>

              <%!-- Description --%>
              <p class="text-sm text-base-content/70 line-clamp-2">
                {event.description || "Deskripsi belum tersedia"}
              </p>

              <%!-- Event Details --%>
              <div class="space-y-2 pt-2 border-t border-base-300">
                <div class="flex items-center gap-2 text-sm text-base-content/80">
                  <.icon name="hero-calendar" class="size-4 text-primary flex-shrink-0" />
                  <span class="line-clamp-1">{format_date_range(event)}</span>
                </div>

                <div class="flex items-center gap-2 text-sm text-base-content/80">
                  <.icon name="hero-map-pin" class="size-4 text-primary flex-shrink-0" />
                  <span class="line-clamp-1">{venue_text(event)}</span>
                </div>

                <div class="flex items-center gap-2 text-sm text-base-content/80">
                  <.icon name="hero-users" class="size-4 text-primary flex-shrink-0" />
                  <span>{registration_summary(event)}</span>
                </div>
              </div>

              <%!-- Tags --%>
              <%= if event.tags && length(event.tags) > 0 do %>
                <div class="flex flex-wrap gap-1.5 pt-2">
                  <%= for tag <- Enum.take(event.tags, 3) do %>
                    <span class="px-2 py-0.5 bg-base-200 text-base-content/70 rounded-lg text-xs">
                      #{tag}
                    </span>
                  <% end %>
                </div>
              <% end %>

              <%!-- CTA Button --%>
              <.link
                navigate={"/events/#{event.slug}"}
                class="block w-full mt-4 px-4 py-2.5 bg-primary text-primary-content text-center rounded-xl font-semibold hover:brightness-90 transition"
              >
                Lihat Detail
              </.link>
            </div>
          </article>
        </div>

        <%!-- Empty State --%>
        <div
          :if={@events_count == 0}
          class="text-center py-16 px-4"
        >
          <.icon name="hero-calendar-days" class="size-20 text-base-content/20 mx-auto mb-4" />
          <h3 class="text-xl font-semibold text-base-content mb-2">Tidak Ada Event</h3>
          <p class="text-base-content/60 mb-6">
            Belum ada event yang sesuai dengan filter Anda. Coba ubah kriteria pencarian.
          </p>
          <button
            phx-click="clear_filters"
            class="px-6 py-2.5 bg-primary text-primary-content rounded-xl font-semibold hover:brightness-90 transition"
          >
            Hapus Semua Filter
          </button>
        </div>

        <%!-- Load More --%>
        <div :if={@has_more} class="flex justify-center mt-10">
          <button
            phx-click="load_more"
            class="group px-8 py-3 rounded-full border-2 border-primary text-primary font-semibold hover:bg-primary hover:text-primary-content transition-all duration-300 flex items-center gap-2"
          >
            <span>Muat Lebih Banyak</span>
            <.icon
              name="hero-arrow-down"
              class="size-4 group-hover:translate-y-0.5 transition-transform"
            />
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Helper functions

  defp registration_full?(event) do
    event.max_attendees && event.max_attendees > 0 &&
      event.registration_count >= event.max_attendees
  end

  defp registration_closing_soon?(event) do
    if event.registration_closes_at do
      now = DateTime.utc_now()
      diff = DateTime.diff(event.registration_closes_at, now, :hour)
      diff > 0 && diff <= 24
    else
      false
    end
  end

  defp type_label(:webinar), do: "Webinar"
  defp type_label(:seminar), do: "Seminar"
  defp type_label(:workshop), do: "Workshop"
  defp type_label(:exhibition), do: "Pameran"
  defp type_label(:conference), do: "Konferensi"
  defp type_label(:training), do: "Pelatihan"
  defp type_label(:reading_program), do: "Program Baca"
  defp type_label(_), do: "Lainnya"

  defp mode_label(:online), do: "Online"
  defp mode_label(:offline), do: "Offline"
  defp mode_label(:hybrid), do: "Hybrid"
  defp mode_label(_), do: ""

  defp venue_text(event) do
    cond do
      event.mode == :online -> "Online"
      event.venue_city && event.venue_province -> "#{event.venue_city}, #{event.venue_province}"
      event.venue_city -> event.venue_city
      event.venue_province -> event.venue_province
      true -> "Lokasi belum ditentukan"
    end
  end

  defp format_date_range(event) do
    starts = event.starts_at && format_date(event.starts_at)
    ends = event.ends_at && format_date(event.ends_at)

    cond do
      starts && ends && starts == ends -> starts
      starts && ends -> "#{starts} - #{ends}"
      starts -> starts
      true -> "Tanggal belum tersedia"
    end
  end

  defp format_date(datetime) do
    date = DateTime.to_date(datetime)
    day = date.day
    month = month_name(date.month)
    "#{day} #{month}"
  end

  defp month_name(1), do: "Jan"
  defp month_name(2), do: "Feb"
  defp month_name(3), do: "Mar"
  defp month_name(4), do: "Apr"
  defp month_name(5), do: "Mei"
  defp month_name(6), do: "Jun"
  defp month_name(7), do: "Jul"
  defp month_name(8), do: "Agt"
  defp month_name(9), do: "Sep"
  defp month_name(10), do: "Okt"
  defp month_name(11), do: "Nov"
  defp month_name(12), do: "Des"

  defp registration_summary(event) do
    count = event.registration_count || 0
    max = event.max_attendees

    cond do
      max && max > 0 -> "#{count}/#{max} peserta"
      count > 0 -> "#{count} peserta"
      true -> "Belum ada peserta"
    end
  end

  defp format_idr(amount) when is_integer(amount) do
    amount
    |> Integer.to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
  end

  defp format_idr(_), do: "0"
end
