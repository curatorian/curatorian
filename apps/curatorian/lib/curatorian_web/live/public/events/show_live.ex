defmodule CuratorianWeb.Public.Events.ShowLive do
  @moduledoc "Public event detail page (/events/:slug)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  def mount(%{"slug" => slug}, _session, socket) do
    case Public.get_event_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Event tidak ditemukan atau sudah tidak tersedia.")
         |> push_navigate(to: "/events")}

      event ->
        user_id = socket.assigns.current_scope && socket.assigns.current_scope.user.id
        registered = user_id && Public.check_event_registration(user_id, event.id)

        {:ok,
         socket
         |> assign(:page_title, "#{event.title} — Event GLAM Indonesia")
         |> assign(:event, event)
         |> assign(:user_id, user_id)
         |> assign(:is_registered, !!registered)
         |> assign(:registration_open, registration_open?(event))}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-5xl mx-auto py-8 px-4 space-y-6">
        <.link navigate="/events" class="text-sm text-base-content/60 hover:text-base-content">
          <.icon name="hero-arrow-left" class="size-4" /> Kembali ke daftar event
        </.link>

        <header class="bg-base-100 border border-base-300 rounded-2xl p-6 space-y-2">
          <div class="flex flex-wrap items-start justify-between gap-3">
            <div>
              <p class="text-xs uppercase tracking-widest text-base-content/60">
                {event_badge(@event)}
              </p>
              <h1 class="text-3xl font-semibold text-base-content">{@event.title}</h1>
              <p class="text-sm text-base-content/70">{host_name(@event)}</p>
            </div>
            <div class="text-right">
              <p class="text-sm text-base-content/60">{date_range(@event)}</p>
              <p class="text-sm text-base-content/60">{venue_text(@event)}</p>
            </div>
          </div>

          <div class="text-sm text-base-content/75 space-y-1">
            <p>📅 Mulai: {format_datetime(@event.starts_at)}</p>
            <p>⏰ Selesai: {format_datetime(@event.ends_at)}</p>
            <p>👥 Terdaftar: {@event.registration_count || 0} {slot_text(@event)}</p>
          </div>
        </header>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <section class="lg:col-span-2 space-y-5">
            <article class="bg-base-100 border border-base-300 rounded-2xl p-6">
              <p class="text-sm text-base-content font-semibold mb-2">Deskripsi</p>
              <div class="whitespace-pre-line text-base-content/85 text-sm">
                {@event.description || "-"}
              </div>
            </article>

            <article class="bg-base-100 border border-base-300 rounded-2xl p-6">
              <p class="text-sm text-base-content font-semibold mb-2">Detail</p>
              <div class="text-base-content/80 text-sm space-y-1">
                <p><strong>Mode:</strong> {to_label(@event.mode)}</p>
                <p><strong>Kategori:</strong> {to_label(@event.category)}</p>
                <p><strong>Status:</strong> {to_label(@event.status)}</p>
                <p><strong>Jenis:</strong> {to_label(@event.event_type)}</p>
              </div>
            </article>
          </section>

          <aside class="space-y-4">
            <div class="bg-base-100 border border-base-300 rounded-2xl p-4 space-y-2 text-sm text-base-content/80">
              <p>
                <strong>Pendaftaran dibuka:</strong> {format_optional_datetime(
                  @event.registration_opens_at
                )}
              </p>
              <p>
                <strong>Pendaftaran ditutup:</strong> {format_optional_datetime(
                  @event.registration_closes_at
                )}
              </p>
              <p><strong>Kuota:</strong> {slot_text(@event)}</p>
            </div>

            <div class="bg-base-100 border border-base-300 rounded-2xl p-4">
              <%= if @event.status in [:canceled, :registration_closed] do %>
                <span class="inline-flex items-center justify-center w-full px-4 py-2 rounded-xl bg-base-200 text-base-content font-semibold">
                  Pendaftaran Ditutup
                </span>
              <% else %>
                <%= if not @registration_open do %>
                  <span class="inline-flex items-center justify-center w-full px-4 py-2 rounded-xl bg-base-200 text-base-content font-semibold">
                    Pendaftaran Belum Dibuka
                  </span>
                <% else %>
                  <%= if @is_registered do %>
                    <span class="inline-flex items-center justify-center w-full px-4 py-2 rounded-xl bg-secondary text-secondary-content font-semibold">
                      Sudah Terdaftar
                    </span>
                  <% else %>
                    <%= if is_nil(@user_id) do %>
                      <.link
                        navigate="/login?return_to=/events/#{@event.slug}"
                        class="inline-flex items-center justify-center w-full px-4 py-2 rounded-xl bg-primary text-primary-content font-semibold"
                      >
                        Masuk untuk daftar
                      </.link>
                    <% else %>
                      <button
                        disabled
                        class="inline-flex items-center justify-center w-full px-4 py-2 rounded-xl bg-primary text-primary-content font-semibold"
                      >
                        Daftar Sekarang
                      </button>
                    <% end %>
                  <% end %>
                <% end %>
              <% end %>
            </div>
          </aside>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp registration_open?(event) do
    now = DateTime.utc_now()

    cond do
      event.status in [:canceled, :draft, :completed] ->
        false

      event.registration_opens_at && DateTime.compare(now, event.registration_opens_at) == :lt ->
        false

      event.registration_closes_at && DateTime.compare(now, event.registration_closes_at) != :lt ->
        false

      event.max_attendees && event.max_attendees > 0 &&
          event.registration_count >= event.max_attendees ->
        false

      true ->
        true
    end
  end

  defp event_badge(event) do
    [to_label(event.event_type), to_label(event.mode), to_label(event.category)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" • ")
  end

  defp host_name(event) do
    cond do
      event.host_org_page_id -> "Diselenggarakan oleh organisasi"
      event.host_user_id -> "Diselenggarakan oleh pengguna"
      true -> "Tidak diketahui"
    end
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
    if starts && ends, do: "#{starts} – #{ends}", else: "Tanggal tidak tersedia"
  end

  defp slot_text(event) do
    if event.max_attendees && event.max_attendees > 0,
      do: "dari #{event.max_attendees}",
      else: "Tanpa batas"
  end

  defp format_datetime(nil), do: "-"
  defp format_datetime(dt), do: DateTime.to_string(dt)

  defp format_optional_datetime(nil), do: "Tidak ditentukan"
  defp format_optional_datetime(dt), do: DateTime.to_string(dt)

  defp to_label(:online), do: "Online"
  defp to_label(:offline), do: "Offline"
  defp to_label(:hybrid), do: "Hybrid"
  defp to_label(:library), do: "Perpustakaan"
  defp to_label(:archives), do: "Arsip"
  defp to_label(:museum), do: "Museum"
  defp to_label(:gallery), do: "Galeri"
  defp to_label(:education), do: "Pendidikan"
  defp to_label(:research), do: "Penelitian"
  defp to_label(:technology), do: "Teknologi"
  defp to_label(:webinar), do: "Webinar"
  defp to_label(:seminar), do: "Seminar"
  defp to_label(:workshop), do: "Workshop"
  defp to_label(:exhibition), do: "Pameran"
  defp to_label(:conference), do: "Konferensi"
  defp to_label(:training), do: "Pelatihan"
  defp to_label(:canceled), do: "Dibatalkan"
  defp to_label(:published), do: "Dipublikasikan"
  defp to_label(:registration_closed), do: "Pendaftaran Ditutup"
  defp to_label(:ongoing), do: "Berlangsung"
  defp to_label(:completed), do: "Selesai"
  defp to_label(_), do: ""
end
