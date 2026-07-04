defmodule CuratorianWeb.Foyer.FoyerLive do
  @moduledoc "Authenticated user dashboard: events, jobs, collections, and blogs."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    user_id = user.id

    # Load all event-related data
    upcoming_registrations = Public.list_upcoming_registrations_for_user(user_id)
    past_registrations = Public.list_past_registrations_for_user(user_id)
    certificates = Public.list_certificates_for_user_with_events(user_id)
    payments = Public.list_payments_for_user_with_details(user_id)

    # Get attendance records for past events
    past_reg_ids = past_registrations |> Enum.map(fn {reg, _event} -> reg.id end)
    attendances = Public.list_attendances_for_user_registrations(past_reg_ids)

    # Legacy data for other tabs
    registrations = Public.list_event_registrations_by_user(user_id)
    registration_event_ids = registrations |> Enum.map(& &1.event_id) |> Enum.uniq()
    registration_events = Public.list_events_by_ids(registration_event_ids)
    events_created = Public.list_events_created_by_user(user_id)
    applications = Public.list_applications_by_user(user_id)
    job_postings = Public.list_job_postings_by_user(user_id)
    blogs = Public.list_blogs_by_user(user_id)
    followed_orgs = Public.list_orgs_followed_by_user(user_id)

    node_ids = followed_orgs |> Enum.map(& &1.voile_node_id) |> Enum.filter(& &1)
    collections = Public.list_collections_for_orgs_by_node_ids(node_ids)

    {:ok,
     socket
     |> assign(:page_title, "Foyer")
     |> assign(:user, user)
     |> assign(:active_tab, :events)
     |> assign(:event_sub_tab, :upcoming)
     |> assign(:upcoming_registrations, upcoming_registrations)
     |> assign(:past_registrations, past_registrations)
     |> assign(:attendances, attendances)
     |> assign(:certificates, certificates)
     |> assign(:payments, payments)
     |> assign(:registrations, registrations)
     |> assign(:registration_events, Map.new(registration_events, &{&1.id, &1}))
     |> assign(:events_created, events_created)
     |> assign(:applications, applications)
     |> assign(:job_postings, job_postings)
     |> assign(:blogs, blogs)
     |> assign(:followed_orgs, followed_orgs)
     |> assign(:collections, collections)
     |> assign(:selected_detail, nil)
     |> assign(:certificate_search, "")}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    tab_atom =
      case tab do
        "career" -> :career
        "content" -> :content
        "certificates" -> :certificates
        "payments" -> :payments
        _ -> :events
      end

    {:noreply, assign(socket, :active_tab, tab_atom)}
  end

  def handle_event("switch_event_tab", %{"tab" => tab}, socket) do
    tab_atom =
      case tab do
        "past" -> :past
        _ -> :upcoming
      end

    {:noreply, assign(socket, :event_sub_tab, tab_atom)}
  end

  def handle_event("search_certificates", %{"query" => query}, socket) do
    {:noreply, assign(socket, :certificate_search, query)}
  end

  def handle_event("view_detail", %{"id" => id, "type" => type}, socket) do
    detail = %{id: id, type: type}
    {:noreply, assign(socket, :selected_detail, detail)}
  end

  def handle_event("close_detail", _params, socket) do
    {:noreply, assign(socket, :selected_detail, nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen">
        <div class="max-w-6xl mx-auto py-10 px-4 sm:px-6 lg:px-8">
          <%!-- Hero Header --%>
          <header class="relative mb-8 rounded-3xl bg-gradient-to-br from-violet-700 via-indigo-600 to-blue-600 p-8 shadow-2xl shadow-indigo-200/60 dark:shadow-indigo-950/70">
            <div class="absolute top-0 right-0 w-80 h-80 rounded-full bg-white/5 -translate-y-1/2 translate-x-1/3 blur-3xl pointer-events-none">
            </div>
            <div class="absolute bottom-0 left-0 w-56 h-56 rounded-full bg-violet-400/20 translate-y-1/2 -translate-x-1/4 blur-2xl pointer-events-none">
            </div>
            <div class="relative flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6">
              <div class="flex items-center gap-4">
                <div class="flex-shrink-0 w-14 h-14 rounded-2xl bg-white/20 backdrop-blur-sm border border-white/30 flex items-center justify-center text-xl font-bold text-white shadow-inner">
                  {String.first(@user.username || "U") |> String.upcase()}
                </div>
                <div>
                  <p class="text-indigo-200 text-xs font-medium tracking-widest uppercase">
                    Selamat datang kembali
                  </p>
                  <h1 class="text-2xl sm:text-3xl font-bold text-white mt-0.5 tracking-tight">
                    {@user.username}
                  </h1>
                  <div class="flex items-center gap-1.5 mt-1.5">
                    <p class="text-white/60 text-xs">
                      <span class="font-medium text-white/80">Foyer</span>
                      — seperti ruang depan sebuah gedung, tempat pertama yang kamu masuki sebelum menjelajahi lebih jauh.
                    </p>
                    <div class="group relative">
                      <.icon
                        name="hero-question-mark-circle"
                        class="w-3.5 h-3.5 text-white/40 hover:text-white/70 cursor-pointer transition-colors flex-shrink-0"
                      />
                      <div class="glass pointer-events-none absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-56 rounded-xl p-3 text-xs text-white/80 leading-relaxed opacity-0 group-hover:opacity-100 transition-opacity duration-200 z-10">
                        Dalam arsitektur, <span class="font-semibold text-white">foyer</span>
                        adalah ruang penyambut — titik pertemuan antara dunia luar dan dalam. Di sini, semua aktivitasmu hadir dalam satu pandangan.
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div class="flex gap-2.5">
                <div class="rounded-2xl bg-white/15 backdrop-blur-sm border border-white/20 px-4 py-3 text-center min-w-[68px]">
                  <p class="text-2xl font-bold text-white leading-none">{length(@registrations)}</p>
                  <p class="text-xs text-indigo-200 mt-1">Events</p>
                </div>
                <div class="rounded-2xl bg-white/15 backdrop-blur-sm border border-white/20 px-4 py-3 text-center min-w-[68px]">
                  <p class="text-2xl font-bold text-white leading-none">{length(@applications)}</p>
                  <p class="text-xs text-indigo-200 mt-1">Lamaran</p>
                </div>
                <div class="rounded-2xl bg-white/15 backdrop-blur-sm border border-white/20 px-4 py-3 text-center min-w-[68px]">
                  <p class="text-2xl font-bold text-white leading-none">{length(@blogs)}</p>
                  <p class="text-xs text-indigo-200 mt-1">Blog</p>
                </div>
              </div>
            </div>
          </header>

          <%!-- Tab Navigation --%>
          <div class="mb-6 flex flex-wrap items-center gap-1 bg-white border border-slate-200 rounded-2xl p-1.5 shadow-sm w-fit dark:bg-slate-900 dark:border-slate-700">
            <button
              id="tab-events"
              phx-click="switch_tab"
              phx-value-tab="events"
              class={[
                "flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-medium transition-all duration-200",
                if(@active_tab == :events,
                  do:
                    "bg-indigo-600 text-white shadow-md shadow-indigo-300/50 dark:shadow-indigo-900/60",
                  else:
                    "text-slate-500 hover:text-slate-800 hover:bg-slate-50 dark:text-slate-400 dark:hover:text-slate-100 dark:hover:bg-slate-800"
                )
              ]}
            >
              <.icon name="hero-calendar-days" class="w-4 h-4" />
              <span>Events</span>
            </button>
            <button
              id="tab-certificates"
              phx-click="switch_tab"
              phx-value-tab="certificates"
              class={[
                "flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-medium transition-all duration-200",
                if(@active_tab == :certificates,
                  do:
                    "bg-indigo-600 text-white shadow-md shadow-indigo-300/50 dark:shadow-indigo-900/60",
                  else:
                    "text-slate-500 hover:text-slate-800 hover:bg-slate-50 dark:text-slate-400 dark:hover:text-slate-100 dark:hover:bg-slate-800"
                )
              ]}
            >
              <.icon name="hero-academic-cap" class="w-4 h-4" />
              <span>Sertifikat</span>
              <%= if length(@certificates) > 0 do %>
                <span class="ml-1 text-xs bg-white/30 px-1.5 py-0.5 rounded-full">
                  {length(@certificates)}
                </span>
              <% end %>
            </button>
            <button
              id="tab-payments"
              phx-click="switch_tab"
              phx-value-tab="payments"
              class={[
                "flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-medium transition-all duration-200",
                if(@active_tab == :payments,
                  do:
                    "bg-indigo-600 text-white shadow-md shadow-indigo-300/50 dark:shadow-indigo-900/60",
                  else:
                    "text-slate-500 hover:text-slate-800 hover:bg-slate-50 dark:text-slate-400 dark:hover:text-slate-100 dark:hover:bg-slate-800"
                )
              ]}
            >
              <.icon name="hero-credit-card" class="w-4 h-4" />
              <span>Pembayaran</span>
            </button>
            <button
              id="tab-career"
              phx-click="switch_tab"
              phx-value-tab="career"
              class={[
                "flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-medium transition-all duration-200",
                if(@active_tab == :career,
                  do:
                    "bg-indigo-600 text-white shadow-md shadow-indigo-300/50 dark:shadow-indigo-900/60",
                  else:
                    "text-slate-500 hover:text-slate-800 hover:bg-slate-50 dark:text-slate-400 dark:hover:text-slate-100 dark:hover:bg-slate-800"
                )
              ]}
            >
              <.icon name="hero-briefcase" class="w-4 h-4" />
              <span>Karir</span>
            </button>
            <button
              id="tab-content"
              phx-click="switch_tab"
              phx-value-tab="content"
              class={[
                "flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-medium transition-all duration-200",
                if(@active_tab == :content,
                  do:
                    "bg-indigo-600 text-white shadow-md shadow-indigo-300/50 dark:shadow-indigo-900/60",
                  else:
                    "text-slate-500 hover:text-slate-800 hover:bg-slate-50 dark:text-slate-400 dark:hover:text-slate-100 dark:hover:bg-slate-800"
                )
              ]}
            >
              <.icon name="hero-book-open" class="w-4 h-4" />
              <span>Konten</span>
            </button>
          </div>

          <%!-- Events Tab --%>
          <%= if @active_tab == :events do %>
            <%!-- Event Sub-tabs --%>
            <div class="mb-4 flex items-center gap-1 bg-slate-50 border border-slate-100 rounded-xl p-1 w-fit dark:bg-slate-800/50 dark:border-slate-700/50">
              <button
                id="event-tab-upcoming"
                phx-click="switch_event_tab"
                phx-value-tab="upcoming"
                class={[
                  "px-4 py-2 rounded-lg text-xs font-medium transition-all duration-200",
                  if(@event_sub_tab == :upcoming,
                    do: "bg-white text-slate-800 shadow-sm dark:bg-slate-700 dark:text-slate-100",
                    else:
                      "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
                  )
                ]}
              >
                Mendatang
              </button>
              <button
                id="event-tab-past"
                phx-click="switch_event_tab"
                phx-value-tab="past"
                class={[
                  "px-4 py-2 rounded-lg text-xs font-medium transition-all duration-200",
                  if(@event_sub_tab == :past,
                    do: "bg-white text-slate-800 shadow-sm dark:bg-slate-700 dark:text-slate-100",
                    else:
                      "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
                  )
                ]}
              >
                Telah Berlalu
              </button>
            </div>

            <%= if @event_sub_tab == :upcoming do %>
              <%!-- Upcoming Events Section --%>
              <div class="space-y-4">
                <div class="flex items-center justify-between">
                  <div>
                    <h3 class="text-lg font-bold text-slate-900 dark:text-slate-100">
                      Event Mendatang yang Terdaftar
                    </h3>
                    <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                      Event yang akan datang dan telah kamu daftarkan
                    </p>
                  </div>
                  <span class="text-xs font-semibold text-indigo-600 bg-indigo-50 px-3 py-1.5 rounded-full dark:bg-indigo-900/40 dark:text-indigo-400">
                    {length(@upcoming_registrations)} Event
                  </span>
                </div>

                <%= if @upcoming_registrations == [] do %>
                  <div class="rounded-2xl border border-dashed border-slate-200 bg-slate-50/50 p-12 text-center dark:border-slate-700 dark:bg-slate-800/30">
                    <div class="w-16 h-16 rounded-2xl bg-gradient-to-br from-indigo-500 to-violet-600 flex items-center justify-center mb-4 mx-auto shadow-lg shadow-indigo-200/50 dark:shadow-indigo-900/30">
                      <.icon name="hero-calendar-days" class="w-8 h-8 text-white" />
                    </div>
                    <h4 class="text-base font-semibold text-slate-800 mb-1 dark:text-slate-200">
                      Belum Ada Event Mendatang
                    </h4>
                    <p class="text-sm text-slate-500 mb-4 dark:text-slate-400">
                      Kamu belum terdaftar di event apapun. Jelajahi event menarik sekarang!
                    </p>
                    <.link
                      navigate="/events"
                      class="inline-flex items-center gap-2 px-6 py-2.5 rounded-xl bg-gradient-to-r from-indigo-600 to-violet-600 hover:from-indigo-700 hover:to-violet-700 !text-white text-sm font-semibold transition-all shadow-lg shadow-indigo-200/50 hover:shadow-xl dark:shadow-indigo-900/30"
                    >
                      <.icon name="hero-magnifying-glass" class="w-4 h-4" /> Jelajahi Event
                    </.link>
                  </div>
                <% else %>
                  <div class="grid gap-4">
                    <%= for {reg, event} <- @upcoming_registrations do %>
                      <div class="group rounded-2xl border border-slate-200 bg-white hover:border-indigo-300 hover:shadow-lg hover:shadow-indigo-100/50 transition-all duration-200 overflow-hidden dark:border-slate-700 dark:bg-slate-900 dark:hover:border-indigo-700 dark:hover:shadow-indigo-900/20">
                        <div class="p-5">
                          <div class="flex flex-col sm:flex-row sm:items-start gap-4">
                            <%!-- Event Info --%>
                            <div class="flex-1 min-w-0">
                              <div class="flex items-start gap-3 mb-2">
                                <div class="flex-shrink-0 w-12 h-12 rounded-xl bg-gradient-to-br from-indigo-500 to-violet-600 flex items-center justify-center shadow-md">
                                  <.icon
                                    name={
                                      if event.mode == :online,
                                        do: "hero-video-camera",
                                        else: "hero-map-pin"
                                    }
                                    class="w-6 h-6 text-white"
                                  />
                                </div>
                                <div class="flex-1 min-w-0">
                                  <.link
                                    navigate={"/events/#{event.slug}"}
                                    class="text-base font-semibold text-slate-900 hover:text-indigo-600 transition-colors line-clamp-2 dark:text-slate-100 dark:hover:text-indigo-400"
                                  >
                                    {event.title}
                                  </.link>
                                  <div class="flex flex-wrap items-center gap-2 mt-1.5">
                                    <span class="inline-flex items-center gap-1 text-xs text-slate-500 dark:text-slate-400">
                                      <.icon name="hero-calendar" class="w-3.5 h-3.5" />
                                      {format_date(event.starts_at)}
                                    </span>
                                    <span class="text-slate-300 dark:text-slate-600">•</span>
                                    <span class="inline-flex items-center gap-1 text-xs text-slate-500 dark:text-slate-400">
                                      <.icon name="hero-clock" class="w-3.5 h-3.5" />
                                      {event.duration_minutes || 60} menit
                                    </span>
                                    <%= if event.mode != :offline do %>
                                      <span class="text-slate-300 dark:text-slate-600">•</span>
                                      <span class="inline-flex items-center gap-1 text-xs text-indigo-600 font-medium dark:text-indigo-400">
                                        <.icon name="hero-globe-alt" class="w-3.5 h-3.5" />
                                        {String.capitalize(to_string(event.mode))}
                                      </span>
                                    <% end %>
                                  </div>
                                  <%= if event.venue_name do %>
                                    <p class="text-xs text-slate-500 mt-1 line-clamp-1 dark:text-slate-400">
                                      <.icon name="hero-map-pin" class="w-3 h-3 inline" />
                                      {event.venue_name}
                                    </p>
                                  <% end %>
                                </div>
                              </div>

                              <%!-- Status Badges --%>
                              <div class="flex flex-wrap items-center gap-2 mt-3">
                                <span class={[
                                  "text-xs font-medium px-3 py-1 rounded-full"
                                  | registration_status_classes(reg.status)
                                ]}>
                                  <%= case reg.status do %>
                                    <% :pending -> %>
                                      <.icon name="hero-clock" class="w-3 h-3 inline" />
                                      Menunggu Persetujuan
                                    <% :approved -> %>
                                      <.icon name="hero-check-circle" class="w-3 h-3 inline" />
                                      Disetujui
                                    <% :waitlisted -> %>
                                      <.icon name="hero-queue-list" class="w-3 h-3 inline" />
                                      Daftar Tunggu
                                    <% _ -> %>
                                      {String.capitalize(to_string(reg.status))}
                                  <% end %>
                                </span>

                                <%= if event.is_paid && reg.paid_at do %>
                                  <span class="text-xs font-medium px-3 py-1 rounded-full bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400">
                                    <.icon name="hero-check-badge" class="w-3 h-3 inline" /> Lunas
                                  </span>
                                <% end %>

                                <%= if event.is_paid && is_nil(reg.paid_at) do %>
                                  <span class="text-xs font-medium px-3 py-1 rounded-full bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400">
                                    <.icon name="hero-exclamation-triangle" class="w-3 h-3 inline" />
                                    Belum Bayar
                                  </span>
                                <% end %>
                              </div>
                            </div>

                            <%!-- Actions --%>
                            <div class="flex sm:flex-col gap-2">
                              <%= if event.mode != :offline && event.meeting_url && reg.status == :approved do %>
                                <.link
                                  href={event.meeting_url}
                                  target="_blank"
                                  class="flex items-center justify-center gap-1.5 px-4 py-2 rounded-xl bg-green-600 hover:bg-green-700 !text-white text-xs font-semibold transition-colors whitespace-nowrap shadow-sm"
                                >
                                  <.icon name="hero-video-camera" class="w-3.5 h-3.5" /> Gabung
                                </.link>
                              <% end %>
                              <.link
                                navigate={"/events/#{event.slug}"}
                                class="flex items-center justify-center gap-1.5 px-4 py-2 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 hover:text-slate-900 text-xs font-medium transition-colors whitespace-nowrap dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700 dark:hover:text-slate-100"
                              >
                                <.icon name="hero-eye" class="w-3.5 h-3.5" /> Detail
                              </.link>
                            </div>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% end %>

            <%!-- Past Events Tab --%>
            <%= if @event_sub_tab == :past do %>
              <div class="space-y-4">
                <div class="flex items-center justify-between">
                  <div>
                    <h3 class="text-lg font-bold text-slate-900 dark:text-slate-100">
                      Event yang Telah Berlalu
                    </h3>
                    <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                      Riwayat event yang pernah kamu ikuti
                    </p>
                  </div>
                  <span class="text-xs font-semibold text-slate-600 bg-slate-50 px-3 py-1.5 rounded-full dark:bg-slate-700/40 dark:text-slate-300">
                    {length(@past_registrations)} Event
                  </span>
                </div>

                <%= if @past_registrations == [] do %>
                  <div class="rounded-2xl border border-dashed border-slate-200 bg-slate-50/50 p-12 text-center dark:border-slate-700 dark:bg-slate-800/30">
                    <div class="w-16 h-16 rounded-2xl bg-gradient-to-br from-slate-400 to-slate-600 flex items-center justify-center mb-4 mx-auto shadow-lg shadow-slate-200/50 dark:shadow-slate-900/30">
                      <.icon name="hero-archive-box" class="w-8 h-8 text-white" />
                    </div>
                    <h4 class="text-base font-semibold text-slate-800 mb-1 dark:text-slate-200">
                      Belum Ada Riwayat Event
                    </h4>
                    <p class="text-sm text-slate-500 mb-4 dark:text-slate-400">
                      Kamu belum pernah mengikuti event apapun.
                    </p>
                  </div>
                <% else %>
                  <div class="grid gap-4">
                    <%= for {reg, event} <- @past_registrations do %>
                      <% attendance = Map.get(@attendances, reg.id) %>
                      <% has_certificate =
                        Enum.any?(@certificates, fn {cert, _e} -> cert.registration_id == reg.id end) %>
                      <div class="group rounded-2xl border border-slate-200 bg-white hover:border-slate-300 hover:shadow-md transition-all duration-200 overflow-hidden dark:border-slate-700 dark:bg-slate-900 dark:hover:border-slate-600">
                        <div class="p-5">
                          <div class="flex flex-col sm:flex-row sm:items-start gap-4">
                            <%!-- Event Info --%>
                            <div class="flex-1 min-w-0">
                              <div class="flex items-start gap-3 mb-2">
                                <div class="flex-shrink-0 w-12 h-12 rounded-xl bg-gradient-to-br from-slate-400 to-slate-600 flex items-center justify-center shadow-md opacity-75">
                                  <.icon name="hero-check-circle" class="w-6 h-6 text-white" />
                                </div>
                                <div class="flex-1 min-w-0">
                                  <.link
                                    navigate={"/events/#{event.slug}"}
                                    class="text-base font-semibold text-slate-900 hover:text-indigo-600 transition-colors line-clamp-2 dark:text-slate-100 dark:hover:text-indigo-400"
                                  >
                                    {event.title}
                                  </.link>
                                  <div class="flex flex-wrap items-center gap-2 mt-1.5">
                                    <span class="inline-flex items-center gap-1 text-xs text-slate-500 dark:text-slate-400">
                                      <.icon name="hero-calendar" class="w-3.5 h-3.5" />
                                      {format_date(event.starts_at)}
                                    </span>
                                    <%= if event.venue_name do %>
                                      <span class="text-slate-300 dark:text-slate-600">•</span>
                                      <span class="inline-flex items-center gap-1 text-xs text-slate-500 line-clamp-1 dark:text-slate-400">
                                        <.icon name="hero-map-pin" class="w-3 h-3" />
                                        {event.venue_name}
                                      </span>
                                    <% end %>
                                  </div>
                                </div>
                              </div>

                              <%!-- Status & Achievements --%>
                              <div class="flex flex-wrap items-center gap-2 mt-3">
                                <%= if attendance do %>
                                  <span class="text-xs font-medium px-3 py-1 rounded-full bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
                                    <.icon name="hero-check-badge" class="w-3 h-3 inline" /> Hadir
                                  </span>
                                <% else %>
                                  <span class="text-xs font-medium px-3 py-1 rounded-full bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400">
                                    <.icon name="hero-x-circle" class="w-3 h-3 inline" /> Tidak Hadir
                                  </span>
                                <% end %>

                                <%= if has_certificate do %>
                                  <span class="text-xs font-medium px-3 py-1 rounded-full bg-violet-50 text-violet-700 dark:bg-violet-900/30 dark:text-violet-400">
                                    <.icon name="hero-academic-cap" class="w-3 h-3 inline" />
                                    Tersertifikasi
                                  </span>
                                <% end %>
                              </div>
                            </div>

                            <%!-- Actions --%>
                            <div class="flex sm:flex-col gap-2">
                              <%= if has_certificate do %>
                                <.link
                                  phx-click="switch_tab"
                                  phx-value-tab="certificates"
                                  class="flex items-center justify-center gap-1.5 px-4 py-2 rounded-xl bg-violet-600 hover:bg-violet-700 !text-white text-xs font-semibold transition-colors whitespace-nowrap shadow-sm cursor-pointer"
                                >
                                  <.icon name="hero-arrow-down-tray" class="w-3.5 h-3.5" /> Sertifikat
                                </.link>
                              <% end %>
                              <.link
                                navigate={"/events/#{event.slug}"}
                                class="flex items-center justify-center gap-1.5 px-4 py-2 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 hover:text-slate-900 text-xs font-medium transition-colors whitespace-nowrap dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700 dark:hover:text-slate-100"
                              >
                                <.icon name="hero-eye" class="w-3.5 h-3.5" /> Detail
                              </.link>
                            </div>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% end %>
          <% end %>

          <%!-- Certificates Tab --%>
          <%= if @active_tab == :certificates do %>
            <div class="space-y-4">
              <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-2">
                <div>
                  <h3 class="text-lg font-bold text-slate-900 dark:text-slate-100">
                    Sertifikat Saya
                  </h3>
                  <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                    Koleksi sertifikat kehadiran dari event yang pernah kamu ikuti
                  </p>
                </div>
                <span class="text-xs font-semibold text-violet-600 bg-violet-50 px-3 py-1.5 rounded-full dark:bg-violet-900/40 dark:text-violet-400">
                  {length(@certificates)} Sertifikat
                </span>
              </div>

              <%= if @certificates == [] do %>
                <div class="rounded-2xl border border-dashed border-slate-200 bg-slate-50/50 p-12 text-center dark:border-slate-700 dark:bg-slate-800/30">
                  <div class="w-16 h-16 rounded-2xl bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center mb-4 mx-auto shadow-lg shadow-violet-200/50 dark:shadow-violet-900/30">
                    <.icon name="hero-academic-cap" class="w-8 h-8 text-white" />
                  </div>
                  <h4 class="text-base font-semibold text-slate-800 mb-1 dark:text-slate-200">
                    Belum Ada Sertifikat
                  </h4>
                  <p class="text-sm text-slate-500 mb-4 dark:text-slate-400">
                    Sertifikat akan otomatis diterbitkan setelah kamu menghadiri event dan memenuhi persyaratan.
                  </p>
                  <.link
                    navigate="/events"
                    class="inline-flex items-center gap-2 px-6 py-2.5 rounded-xl bg-gradient-to-r from-violet-600 to-purple-600 hover:from-violet-700 hover:to-purple-700 !text-white text-sm font-semibold transition-all shadow-lg shadow-violet-200/50 hover:shadow-xl dark:shadow-violet-900/30"
                  >
                    <.icon name="hero-calendar-days" class="w-4 h-4" /> Ikuti Event
                  </.link>
                </div>
              <% else %>
                <%!-- Certificate Grid --%>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  <%= for {cert, event} <- @certificates do %>
                    <div class="group relative rounded-2xl border border-slate-200 bg-white hover:border-violet-300 hover:shadow-xl hover:shadow-violet-100/50 transition-all duration-300 overflow-hidden dark:border-slate-700 dark:bg-slate-900 dark:hover:border-violet-600 dark:hover:shadow-violet-900/20">
                      <%!-- Certificate Preview --%>
                      <div class="aspect-[4/3] bg-gradient-to-br from-violet-50 to-purple-50 dark:from-slate-800 dark:to-slate-700 p-6 flex flex-col items-center justify-center text-center relative overflow-hidden">
                        <div class="absolute inset-0 opacity-10">
                          <div class="absolute top-0 left-0 w-32 h-32 bg-violet-400 rounded-full -translate-x-1/2 -translate-y-1/2 blur-2xl">
                          </div>
                          <div class="absolute bottom-0 right-0 w-32 h-32 bg-purple-400 rounded-full translate-x-1/2 translate-y-1/2 blur-2xl">
                          </div>
                        </div>
                        <div class="relative z-10">
                          <div class="w-14 h-14 rounded-full bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center mb-3 mx-auto shadow-lg">
                            <.icon name="hero-academic-cap" class="w-7 h-7 text-white" />
                          </div>
                          <h4 class="text-sm font-bold text-slate-800 mb-1 line-clamp-2 dark:text-slate-100">
                            {event.title}
                          </h4>
                          <p class="text-xs text-slate-500 dark:text-slate-400">
                            {Calendar.strftime(cert.event_date, "%d %B %Y")}
                          </p>
                        </div>
                      </div>

                      <%!-- Certificate Info --%>
                      <div class="p-4 space-y-3">
                        <div class="flex items-start justify-between gap-2">
                          <div class="flex-1 min-w-0">
                            <p class="text-xs text-slate-500 dark:text-slate-400">
                              No. Sertifikat
                            </p>
                            <p class="text-xs font-mono font-semibold text-slate-800 truncate dark:text-slate-200">
                              {cert.certificate_number}
                            </p>
                          </div>
                        </div>

                        <div class="flex items-center gap-1.5 text-xs text-slate-500 dark:text-slate-400">
                          <.icon name="hero-check-circle" class="w-3.5 h-3.5 text-emerald-500" />
                          <span>Terverifikasi</span>
                        </div>

                        <%!-- Actions --%>
                        <div class="flex gap-2 pt-2 border-t border-slate-100 dark:border-slate-800">
                          <%= if cert.pdf_url do %>
                            <.link
                              href={cert.pdf_url}
                              target="_blank"
                              class="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg bg-violet-600 hover:bg-violet-700 !text-white text-xs font-semibold transition-colors"
                            >
                              <.icon name="hero-arrow-down-tray" class="w-3.5 h-3.5" /> Unduh
                            </.link>
                          <% end %>
                          <.link
                            navigate={"/events/#{event.slug}"}
                            class="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 text-xs font-medium transition-colors dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700"
                          >
                            <.icon name="hero-eye" class="w-3.5 h-3.5" /> Event
                          </.link>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>

          <%!-- Payments Tab --%>
          <%= if @active_tab == :payments do %>
            <div class="space-y-4">
              <div class="flex items-center justify-between">
                <div>
                  <h3 class="text-lg font-bold text-slate-900 dark:text-slate-100">
                    Riwayat Pembayaran Event
                  </h3>
                  <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                    Semua transaksi pembayaran untuk pendaftaran event
                  </p>
                </div>
                <span class="text-xs font-semibold text-slate-600 bg-slate-50 px-3 py-1.5 rounded-full dark:bg-slate-700/40 dark:text-slate-300">
                  {length(@payments)} Transaksi
                </span>
              </div>

              <%= if @payments == [] do %>
                <div class="rounded-2xl border border-dashed border-slate-200 bg-slate-50/50 p-12 text-center dark:border-slate-700 dark:bg-slate-800/30">
                  <div class="w-16 h-16 rounded-2xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center mb-4 mx-auto shadow-lg shadow-emerald-200/50 dark:shadow-emerald-900/30">
                    <.icon name="hero-credit-card" class="w-8 h-8 text-white" />
                  </div>
                  <h4 class="text-base font-semibold text-slate-800 mb-1 dark:text-slate-200">
                    Belum Ada Transaksi
                  </h4>
                  <p class="text-sm text-slate-500 mb-4 dark:text-slate-400">
                    Kamu belum pernah melakukan pembayaran untuk event berbayar.
                  </p>
                </div>
              <% else %>
                <div class="space-y-3">
                  <%= for {payment, event, reg} <- @payments do %>
                    <div class="rounded-2xl border border-slate-200 bg-white hover:border-slate-300 hover:shadow-md transition-all duration-200 overflow-hidden dark:border-slate-700 dark:bg-slate-900">
                      <div class="p-5">
                        <div class="flex flex-col sm:flex-row sm:items-start gap-4">
                          <%!-- Payment Info --%>
                          <div class="flex-1 min-w-0">
                            <div class="flex items-start gap-3">
                              <div class="flex-shrink-0 w-10 h-10 rounded-lg bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center shadow-md">
                                <.icon
                                  name={
                                    if payment.status == :success,
                                      do: "hero-check-circle",
                                      else: "hero-clock"
                                  }
                                  class="w-5 h-5 text-white"
                                />
                              </div>
                              <div class="flex-1 min-w-0">
                                <.link
                                  navigate={"/events/#{event.slug}"}
                                  class="text-sm font-semibold text-slate-900 hover:text-indigo-600 transition-colors line-clamp-2 dark:text-slate-100 dark:hover:text-indigo-400"
                                >
                                  {event.title}
                                </.link>
                                <div class="flex flex-wrap items-center gap-2 mt-1.5">
                                  <span class="text-xs text-slate-500 dark:text-slate-400">
                                    Order ID: {payment.gateway_order_id || "N/A"}
                                  </span>
                                  <span class="text-slate-300 dark:text-slate-600">•</span>
                                  <span class="text-xs text-slate-500 dark:text-slate-400">
                                    {format_date(payment.inserted_at)}
                                  </span>
                                </div>
                              </div>
                            </div>

                            <%!-- Payment Details --%>
                            <div class="mt-3 flex flex-wrap items-center gap-3">
                              <span class={[
                                "text-xs font-medium px-3 py-1 rounded-full",
                                case payment.status do
                                  :success ->
                                    "bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"

                                  :pending ->
                                    "bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"

                                  :failed ->
                                    "bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400"

                                  :expired ->
                                    "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400"

                                  _ ->
                                    "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400"
                                end
                              ]}>
                                <%= case payment.status do %>
                                  <% :success -> %>
                                    <.icon name="hero-check-badge" class="w-3 h-3 inline" /> Berhasil
                                  <% :pending -> %>
                                    <.icon name="hero-clock" class="w-3 h-3 inline" /> Menunggu
                                  <% :failed -> %>
                                    <.icon name="hero-x-circle" class="w-3 h-3 inline" /> Gagal
                                  <% :expired -> %>
                                    <.icon name="hero-exclamation-triangle" class="w-3 h-3 inline" />
                                    Kedaluwarsa
                                  <% _ -> %>
                                    {String.capitalize(to_string(payment.status))}
                                <% end %>
                              </span>

                              <%= if payment.payment_method do %>
                                <span class="text-xs text-slate-500 dark:text-slate-400">
                                  via {String.upcase(payment.payment_method)}
                                </span>
                              <% end %>
                            </div>
                          </div>

                          <%!-- Amount & Actions --%>
                          <div class="flex flex-col items-end gap-3">
                            <div class="text-right">
                              <p class="text-xs text-slate-500 dark:text-slate-400">
                                Total Bayar
                              </p>
                              <p class="text-lg font-bold text-slate-900 dark:text-slate-100">
                                Rp {format_currency(payment.gross_amount_idr)}
                              </p>
                            </div>

                            <%= if payment.status == :pending do %>
                              <button class="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 !text-white text-xs font-semibold transition-colors whitespace-nowrap shadow-sm">
                                <.icon name="hero-credit-card" class="w-3.5 h-3.5" /> Bayar Sekarang
                              </button>
                            <% end %>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>

          <%!-- Career Tab --%>
          <%= if @active_tab == :career do %>
            <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
              <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm hover:shadow-md transition-shadow duration-200 dark:border-slate-700 dark:bg-slate-900">
                <div class="flex items-center justify-between mb-5">
                  <div class="flex items-center gap-3">
                    <div class="p-2 rounded-xl bg-emerald-50 dark:bg-emerald-900/30">
                      <.icon
                        name="hero-document-text"
                        class="w-5 h-5 text-emerald-600 dark:text-emerald-400"
                      />
                    </div>
                    <h5 class="text-base font-semibold text-slate-800 dark:text-slate-100">
                      Lamaran Saya
                    </h5>
                  </div>
                  <span class="text-xs font-semibold text-emerald-600 bg-emerald-50 px-2.5 py-1 rounded-full dark:bg-emerald-900/40 dark:text-emerald-400">
                    {length(@applications)}
                  </span>
                </div>
                <%= if @applications == [] do %>
                  <div class="flex flex-col items-center justify-center py-10 text-center">
                    <div class="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center mb-3 dark:bg-slate-800">
                      <.icon name="hero-document" class="w-6 h-6 text-slate-300 dark:text-slate-600" />
                    </div>
                    <p class="text-sm text-slate-400 dark:text-slate-500">Belum ada lamaran.</p>
                    <.link
                      navigate="/jobs"
                      class="mt-4 inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 !text-white text-xs font-medium transition-colors"
                    >
                      <.icon name="hero-magnifying-glass" class="w-3.5 h-3.5" /> Cari Lowongan
                    </.link>
                  </div>
                <% else %>
                  <div class="space-y-2.5">
                    <%= for app <- Enum.take(@applications, 4) do %>
                      <div class="rounded-xl border border-slate-100 px-4 py-3 hover:border-emerald-200 hover:bg-emerald-50/40 transition-all duration-150 dark:border-slate-800 dark:hover:border-emerald-800 dark:hover:bg-emerald-900/20">
                        <div class="flex items-center justify-between gap-3">
                          <p class="text-sm font-medium text-slate-800 truncate dark:text-slate-200">
                            {Public.get_job_posting_by_id!(app.job_posting_id).title}
                          </p>
                          <span class={[
                            "text-xs font-medium px-2.5 py-0.5 rounded-full flex-shrink-0"
                            | application_status_classes(app.status)
                          ]}>
                            {application_status_label(app.status)}
                          </span>
                        </div>
                      </div>
                    <% end %>
                  </div>
                  <%= if length(@applications) > 4 do %>
                    <div class="mt-3 pt-3 border-t border-slate-100 dark:border-slate-800">
                      <.link
                        navigate="/jobs"
                        class="text-xs font-medium text-emerald-600 hover:text-emerald-500 dark:text-emerald-400 flex items-center gap-1"
                      >
                        Lihat lebih banyak <.icon name="hero-arrow-right" class="w-3.5 h-3.5" />
                      </.link>
                    </div>
                  <% end %>
                <% end %>
              </section>

              <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm hover:shadow-md transition-shadow duration-200 dark:border-slate-700 dark:bg-slate-900">
                <div class="flex items-center justify-between mb-5">
                  <div class="flex items-center gap-3">
                    <div class="p-2 rounded-xl bg-amber-50 dark:bg-amber-900/30">
                      <.icon name="hero-briefcase" class="w-5 h-5 text-amber-600 dark:text-amber-400" />
                    </div>
                    <h5 class="text-base font-semibold text-slate-800 dark:text-slate-100">
                      Lowongan Dipublikasikan
                    </h5>
                  </div>
                  <span class="text-xs font-semibold text-amber-600 bg-amber-50 px-2.5 py-1 rounded-full dark:bg-amber-900/40 dark:text-amber-400">
                    {length(@job_postings)}
                  </span>
                </div>
                <%= if @job_postings == [] do %>
                  <div class="flex flex-col items-center justify-center py-10 text-center">
                    <div class="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center mb-3 dark:bg-slate-800">
                      <.icon name="hero-briefcase" class="w-6 h-6 text-slate-300 dark:text-slate-600" />
                    </div>
                    <p class="text-sm text-slate-400 dark:text-slate-500">Belum ada lowongan.</p>
                    <.link
                      navigate={System.get_env("ATRIUM_URL") <> "/community/jobs/new"}
                      class="mt-4 inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-amber-500 hover:bg-amber-600 !text-white text-xs font-medium transition-colors"
                    >
                      <.icon name="hero-plus" class="w-3.5 h-3.5" /> Pasang Lowongan
                    </.link>
                  </div>
                <% else %>
                  <div class="space-y-2.5">
                    <%= for job <- Enum.take(@job_postings, 4) do %>
                      <div class="rounded-xl border border-slate-100 px-4 py-3 hover:border-amber-200 hover:bg-amber-50/40 transition-all duration-150 dark:border-slate-800 dark:hover:border-amber-800 dark:hover:bg-amber-900/20">
                        <div class="flex items-center justify-between gap-3">
                          <.link
                            navigate={"/jobs/#{job.slug}"}
                            class="text-sm font-medium text-slate-800 hover:text-amber-600 transition-colors truncate dark:text-slate-200 dark:hover:text-amber-400"
                          >
                            {job.title}
                          </.link>
                          <span class={[
                            "text-xs font-medium px-2.5 py-0.5 rounded-full flex-shrink-0"
                            | job_status_classes(job.status)
                          ]}>
                            {to_job_status(job.status)}
                          </span>
                        </div>
                      </div>
                    <% end %>
                  </div>
                  <%= if length(@job_postings) > 4 do %>
                    <div class="mt-3 pt-3 border-t border-slate-100 dark:border-slate-800">
                      <.link
                        navigate="/jobs"
                        class="text-xs font-medium text-amber-600 hover:text-amber-500 dark:text-amber-400 flex items-center gap-1"
                      >
                        Lihat lebih banyak <.icon name="hero-arrow-right" class="w-3.5 h-3.5" />
                      </.link>
                    </div>
                  <% end %>
                <% end %>
              </section>
            </div>
          <% end %>

          <%!-- Content Tab --%>
          <%= if @active_tab == :content do %>
            <div class="space-y-6">
              <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
                <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm hover:shadow-md transition-shadow duration-200 dark:border-slate-700 dark:bg-slate-900">
                  <div class="flex items-center justify-between mb-5">
                    <div class="flex items-center gap-3">
                      <div class="p-2 rounded-xl bg-sky-50 dark:bg-sky-900/30">
                        <.icon
                          name="hero-building-office"
                          class="w-5 h-5 text-sky-600 dark:text-sky-400"
                        />
                      </div>
                      <h5 class="text-base font-semibold text-slate-800 dark:text-slate-100">
                        Organisasi Diikuti
                      </h5>
                    </div>
                    <span class="text-xs font-semibold text-sky-600 bg-sky-50 px-2.5 py-1 rounded-full dark:bg-sky-900/40 dark:text-sky-400">
                      {length(@followed_orgs)}
                    </span>
                  </div>
                  <%= if @followed_orgs == [] do %>
                    <div class="flex flex-col items-center justify-center py-10 text-center">
                      <div class="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center mb-3 dark:bg-slate-800">
                        <.icon
                          name="hero-building-office"
                          class="w-6 h-6 text-slate-300 dark:text-slate-600"
                        />
                      </div>
                      <p class="text-sm text-slate-400 dark:text-slate-500">
                        Belum bergabung organisasi.
                      </p>
                      <.link
                        navigate="/orgs"
                        class="mt-4 inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-sky-600 hover:bg-sky-700 !text-white text-xs font-medium transition-colors"
                      >
                        <.icon name="hero-magnifying-glass" class="w-3.5 h-3.5" /> Temukan Organisasi
                      </.link>
                    </div>
                  <% else %>
                    <div class="space-y-2.5">
                      <%= for org <- Enum.take(@followed_orgs, 4) do %>
                        <div class="rounded-xl border border-slate-100 px-4 py-3 hover:border-sky-200 hover:bg-sky-50/40 transition-all duration-150 dark:border-slate-800 dark:hover:border-sky-800 dark:hover:bg-sky-900/20">
                          <.link
                            navigate={"/orgs/#{org.slug}"}
                            class="text-sm font-medium text-slate-800 hover:text-sky-600 transition-colors dark:text-slate-200 dark:hover:text-sky-400"
                          >
                            {org.name}
                          </.link>
                        </div>
                      <% end %>
                    </div>
                    <%= if length(@followed_orgs) > 4 do %>
                      <div class="mt-3 pt-3 border-t border-slate-100 dark:border-slate-800">
                        <.link
                          navigate="/orgs"
                          class="text-xs font-medium text-sky-600 hover:text-sky-500 dark:text-sky-400 flex items-center gap-1"
                        >
                          Lihat lebih banyak <.icon name="hero-arrow-right" class="w-3.5 h-3.5" />
                        </.link>
                      </div>
                    <% end %>
                  <% end %>
                </section>

                <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm hover:shadow-md transition-shadow duration-200 dark:border-slate-700 dark:bg-slate-900">
                  <div class="flex items-center justify-between mb-5">
                    <div class="flex items-center gap-3">
                      <div class="p-2 rounded-xl bg-teal-50 dark:bg-teal-900/30">
                        <.icon
                          name="hero-rectangle-stack"
                          class="w-5 h-5 text-teal-600 dark:text-teal-400"
                        />
                      </div>
                      <h5 class="text-base font-semibold text-slate-800 dark:text-slate-100">
                        Koleksi Organisasi
                      </h5>
                    </div>
                    <span class="text-xs font-semibold text-teal-600 bg-teal-50 px-2.5 py-1 rounded-full dark:bg-teal-900/40 dark:text-teal-400">
                      {length(@collections)}
                    </span>
                  </div>
                  <%= if @collections == [] do %>
                    <div class="flex flex-col items-center justify-center py-10 text-center">
                      <div class="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center mb-3 dark:bg-slate-800">
                        <.icon
                          name="hero-rectangle-stack"
                          class="w-6 h-6 text-slate-300 dark:text-slate-600"
                        />
                      </div>
                      <p class="text-sm text-slate-400 dark:text-slate-500">
                        Belum ada koleksi yang ditemukan.
                      </p>
                      <.link
                        navigate="/orgs"
                        class="mt-4 inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-teal-600 hover:bg-teal-700 !text-white text-xs font-medium transition-colors"
                      >
                        <.icon name="hero-magnifying-glass" class="w-3.5 h-3.5" /> Jelajahi Organisasi
                      </.link>
                    </div>
                  <% else %>
                    <div class="space-y-2.5">
                      <%= for collection <- Enum.take(@collections, 4) do %>
                        <div class="rounded-xl border border-slate-100 px-4 py-3 hover:border-teal-200 hover:bg-teal-50/40 transition-all duration-150 dark:border-slate-800 dark:hover:border-teal-800 dark:hover:bg-teal-900/20">
                          <p class="text-sm font-medium text-slate-800 dark:text-slate-200">
                            {collection.title}
                          </p>
                        </div>
                      <% end %>
                    </div>
                    <%= if length(@collections) > 4 do %>
                      <div class="mt-3 pt-3 border-t border-slate-100 dark:border-slate-800">
                        <.link
                          navigate="/orgs"
                          class="text-xs font-medium text-teal-600 hover:text-teal-500 dark:text-teal-400 flex items-center gap-1"
                        >
                          Lihat lebih banyak <.icon name="hero-arrow-right" class="w-3.5 h-3.5" />
                        </.link>
                      </div>
                    <% end %>
                  <% end %>
                </section>
              </div>

              <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm hover:shadow-md transition-shadow duration-200 dark:border-slate-700 dark:bg-slate-900">
                <div class="flex items-center justify-between mb-5">
                  <div class="flex items-center gap-3">
                    <div class="p-2 rounded-xl bg-rose-50 dark:bg-rose-900/30">
                      <.icon
                        name="hero-pencil-square"
                        class="w-5 h-5 text-rose-600 dark:text-rose-400"
                      />
                    </div>
                    <h5 class="text-base font-semibold text-slate-800 dark:text-slate-100">
                      Blog Saya
                    </h5>
                  </div>
                  <span class="text-xs font-semibold text-rose-600 bg-rose-50 px-2.5 py-1 rounded-full dark:bg-rose-900/40 dark:text-rose-400">
                    {length(@blogs)}
                  </span>
                </div>
                <%= if @blogs == [] do %>
                  <div class="flex flex-col items-center justify-center py-10 text-center">
                    <div class="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center mb-3 dark:bg-slate-800">
                      <.icon name="hero-pencil" class="w-6 h-6 text-slate-300 dark:text-slate-600" />
                    </div>
                    <p class="text-sm text-slate-400 dark:text-slate-500">Belum menulis blog.</p>
                    <.link
                      navigate={System.get_env("ATRIUM_URL") <> "/community/blog/new"}
                      class="mt-4 inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 !text-white text-xs font-medium transition-colors"
                    >
                      <.icon name="hero-plus" class="w-3.5 h-3.5" /> Tulis Blog
                    </.link>
                  </div>
                <% else %>
                  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                    <%= for post <- Enum.take(@blogs, 4) do %>
                      <div class="rounded-xl border border-slate-100 px-4 py-3 hover:border-rose-200 hover:bg-rose-50/40 transition-all duration-150 dark:border-slate-800 dark:hover:border-rose-800 dark:hover:bg-rose-900/20">
                        <.link
                          navigate={"/u/#{@user.username}/blog/#{post.slug}"}
                          class="text-sm font-medium text-slate-800 hover:text-rose-600 transition-colors line-clamp-2 dark:text-slate-200 dark:hover:text-rose-400"
                        >
                          {post.title}
                        </.link>
                      </div>
                    <% end %>
                  </div>
                  <%= if length(@blogs) > 4 do %>
                    <div class="mt-3 pt-3 border-t border-slate-100 dark:border-slate-800">
                      <.link
                        navigate={"/u/#{@user.username}/blog"}
                        class="text-xs font-medium text-rose-600 hover:text-rose-500 dark:text-rose-400 flex items-center gap-1"
                      >
                        Lihat lebih banyak <.icon name="hero-arrow-right" class="w-3.5 h-3.5" />
                      </.link>
                    </div>
                  <% end %>
                <% end %>
              </section>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp format_date(nil), do: "-"
  defp format_date(dt), do: DateTime.to_date(dt) |> Date.to_string()

  defp format_currency(amount) when is_integer(amount) do
    amount
    |> to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
  end

  defp format_currency(_), do: "0"

  defp to_label(:draft), do: "Draft"
  defp to_label(:published), do: "Dipublikasikan"
  defp to_label(:registration_closed), do: "Pendaftaran Ditutup"
  defp to_label(:ongoing), do: "Berlangsung"
  defp to_label(:completed), do: "Selesai"
  defp to_label(:canceled), do: "Dibatalkan"
  defp to_label(_), do: "-"

  defp application_status_label(:pending), do: "Baru"
  defp application_status_label(:reviewed), do: "Ditinjau"
  defp application_status_label(:shortlisted), do: "Shortlist"
  defp application_status_label(:rejected), do: "Ditolak"
  defp application_status_label(:hired), do: "Diterima"
  defp application_status_label(_), do: "-"

  defp to_job_status(:active), do: "Aktif"
  defp to_job_status(:filled), do: "Terisi"
  defp to_job_status(_), do: "-"

  defp event_status_classes(:draft),
    do: ["bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400"]

  defp event_status_classes(:published),
    do: ["bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-400"]

  defp event_status_classes(:registration_closed),
    do: ["bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-400"]

  defp event_status_classes(:ongoing),
    do: ["bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-400"]

  defp event_status_classes(:completed),
    do: ["bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400"]

  defp event_status_classes(:canceled),
    do: ["bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-400"]

  defp event_status_classes(_),
    do: ["bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-500"]

  defp registration_status_classes(:pending),
    do: ["bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-400"]

  defp registration_status_classes(:approved),
    do: ["bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-400"]

  defp registration_status_classes(:waitlisted),
    do: ["bg-indigo-100 text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-400"]

  defp registration_status_classes(:confirmed),
    do: ["bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-400"]

  defp registration_status_classes(:attended),
    do: ["bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-400"]

  defp registration_status_classes(:rejected),
    do: ["bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-400"]

  defp registration_status_classes(:canceled),
    do: ["bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400"]

  defp registration_status_classes(:cancelled),
    do: ["bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-400"]

  defp registration_status_classes(:no_show),
    do: ["bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400"]

  defp registration_status_classes(_),
    do: ["bg-indigo-100 text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-400"]

  defp application_status_classes(:pending),
    do: ["bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400"]

  defp application_status_classes(:reviewed),
    do: ["bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-400"]

  defp application_status_classes(:shortlisted),
    do: ["bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-400"]

  defp application_status_classes(:rejected),
    do: ["bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-400"]

  defp application_status_classes(:hired),
    do: ["bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-400"]

  defp application_status_classes(_),
    do: ["bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-500"]

  defp job_status_classes(:active),
    do: ["bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-400"]

  defp job_status_classes(:filled),
    do: ["bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400"]

  defp job_status_classes(_),
    do: ["bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-500"]
end
