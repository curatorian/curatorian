defmodule CuratorianWeb.Public.Events.ShowLive do
  @moduledoc "Public event detail page (/events/:slug)."

  use CuratorianWeb, :live_view

  alias Curatorian.EventPayments
  alias Curatorian.Public
  alias CuratorianWeb.Markdown
  alias CuratorianWeb.Public.Events.TimeFormat

  alias QRCode
  alias QRCode.Render.PngSettings

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Public.get_event_by_slug(slug) do
      nil ->
        raise Ecto.NoResultsError, queryable: "event"

      event ->
        current_scope = socket.assigns.current_scope

        user_id =
          if current_scope && current_scope.user do
            current_scope.user.id
          end

        registration =
          if user_id, do: Public.get_registration_for_user(user_id, event.id), else: nil

        host_org =
          event.host_org_page_id && Public.get_public_org_page_brief(event.host_org_page_id)

        host_user = event.host_user_id && Public.get_public_user_brief(event.host_user_id)

        broadcasts = Public.list_broadcasts_for_event(event.id)

        base = Layouts.meta_base_url()
        cover = Map.get(event, :cover_image_url)
        # Uploaded covers live on the Atrium host: OG images must be absolute
        # and point there, otherwise crawlers fetch a 404 from Curatorian.
        og_cover = cover && Public.asset_url(cover)

        participant = participant_assigns(registration, event)

        {:ok,
         socket
         |> assign(:page_title, "#{event.title} — Event GLAM Indonesia")
         |> assign(:event, event)
         |> assign(:user_id, user_id)
         |> assign(:registration, registration)
         |> assign(:participant, participant)
         |> assign(:host_org, host_org)
         |> assign(:host_user, host_user)
         |> assign(:broadcasts, broadcasts)
         |> assign(:show_registration_form, false)
         |> assign(:cover_modal_open, false)
         |> assign(:code_input, "")
         |> assign(:code_error, nil)
         |> assign_registration_form_prefill(current_scope)
         |> assign(:registration_open, registration_open?(event))
         |> assign(:registration_state, registration_state(event))
         |> assign(:og_title, event.title)
         |> assign(:og_description, event.description)
         |> assign(:og_image, og_cover)
         |> assign(:og_url, "/events/#{event.slug}")
         |> assign(:og_type, "website")
         |> assign(:json_ld, [event_json(event, base, cover)])
         |> assign(
           :twitter_card,
           if(cover, do: "summary_large_image", else: "summary")
         )}
    end
  end

  # Pre-fills the registration form from the account data, so repeat
  # registrants never re-type their details.
  defp assign_registration_form_prefill(socket, current_scope) do
    user = current_scope && current_scope.user

    if user do
      assign(socket,
        prefill_name: user.fullname || "",
        prefill_email: user.email || "",
        prefill_phone: user.phone_number || ""
      )
    else
      assign(socket, prefill_name: "", prefill_email: "", prefill_phone: "")
    end
  end

  @impl true
  def handle_event("register", _params, socket) do
    %{event: event, user_id: user_id} = socket.assigns

    cond do
      is_nil(user_id) ->
        {:noreply, push_navigate(socket, to: "/login?return_to=/events/#{event.slug}")}

      true ->
        {:noreply, assign(socket, :show_registration_form, true)}
    end
  end

  def handle_event("cancel_registration_form", _params, socket) do
    {:noreply, assign(socket, :show_registration_form, false)}
  end

  def handle_event("open_cover_modal", _params, socket) do
    {:noreply, assign(socket, :cover_modal_open, true)}
  end

  def handle_event("close_cover_modal", _params, socket) do
    {:noreply, assign(socket, :cover_modal_open, false)}
  end

  def handle_event("submit_registration", %{"registration" => params}, socket) do
    if params["consent"] != "true" do
      {:noreply, put_flash(socket, :error, "Anda harus menyetujui pemrosesan data.")}
    else
      registration_data = %{
        "name" => String.trim(params["name"] || ""),
        "email" => String.trim(params["email"] || ""),
        "phone" => String.trim(params["phone"] || "")
      }

      do_register(socket, 0, registration_data)
    end
  end

  def handle_event("start_payment", _params, socket) do
    %{event: event, registration: registration, user_id: user_id} = socket.assigns

    cond do
      is_nil(registration) or is_nil(user_id) ->
        {:noreply, put_flash(socket, :error, "Pendaftaran tidak ditemukan.")}

      true ->
        case EventPayments.start_payment(event.id, registration.id, user_id) do
          {:ok, %{redirect_url: redirect_url}} ->
            {:noreply, redirect(socket, external: redirect_url)}

          {:error, _reason} ->
            {:noreply,
             socket
             |> put_flash(
               :warning,
               "Pembayaran online sedang tidak tersedia. Penyelenggara akan menghubungi Anda untuk penyelesaian pembayaran."
             )}
        end
    end
  end

  def handle_event("self_check_in", _params, socket) do
    case socket.assigns.registration do
      nil ->
        {:noreply, socket}

      registration ->
        case Public.self_check_in(registration.id) do
          {:ok, attendance} ->
            {:noreply,
             socket
             |> update(
               :participant,
               &Map.merge(&1, %{
                 self_checkin_active?: false,
                 checked_in_at: attendance.checked_in_at
               })
             )
             |> put_flash(:info, "Kehadiran tercatat!")}

          {:error, :already_checked_in} ->
            {:noreply, put_flash(socket, :info, "Anda sudah check-in untuk event ini.")}

          {:error, :outside_event_window} ->
            {:noreply,
             put_flash(socket, :error, "Check-in hanya tersedia selama event berlangsung.")}

          {:error, reason} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "Check-in mandiri belum aktif: #{reason}. Gunakan kode sesi atau hubungi penyelenggara."
             )}
        end
    end
  end

  # Self check-in from the event page: same server path as the participant
  # page, so attendance lands in `atrium.event_checkpoint_records`.
  def handle_event("submit_code", %{"code" => code}, socket) do
    case socket.assigns.registration do
      nil ->
        {:noreply, socket}

      registration ->
        code = String.upcase(String.trim(code || ""))

        if code == "" do
          {:noreply, assign(socket, :code_error, "Masukkan kode sesi.")}
        else
          handle_check_in(socket, registration, code)
        end
    end
  end

  defp handle_check_in(socket, registration, code) do
    case Public.record_checkpoint_attendance(registration.id, code) do
      {:ok, _record} ->
        count = length(Public.list_checkpoint_records(registration.id))

        {:noreply,
         socket
         |> update(:participant, &Map.put(&1, :checkpoint_count, count))
         |> assign(:code_input, "")
         |> assign(:code_error, nil)
         |> put_flash(:info, "Kehadiran tercatat!")}

      {:error, :invalid_code} ->
        {:noreply, assign(socket, :code_error, "Kode tidak valid atau sudah kedaluwarsa.")}

      {:error, :already_recorded} ->
        {:noreply, assign(socket, :code_error, "Kehadiran sudah tercatat untuk sesi ini.")}

      {:error, :rate_limited} ->
        {:noreply, assign(socket, :code_error, "Terlalu banyak percobaan. Coba lagi nanti.")}

      {:error, :not_approved} ->
        {:noreply,
         assign(
           socket,
           :code_error,
           "Kehadiran hanya bisa dicatat setelah pendaftaran disetujui."
         )}
    end
  end

  defp do_register(socket, amount_paid_idr, registration_data) do
    %{event: event, user_id: user_id} = socket.assigns

    opts = [
      requires_approval: event.requires_approval,
      amount_paid_idr: amount_paid_idr,
      registration_data: registration_data
    ]

    case Public.register_for_event(user_id, event.id, opts) do
      {:ok, registration} ->
        {:noreply,
         socket
         |> assign(:registration, registration)
         |> assign(:show_registration_form, false)
         |> put_flash(:info, "Pendaftaran berhasil dikirim!")}

      {:error, :already_registered} ->
        {:noreply, put_flash(socket, :error, "Anda sudah terdaftar untuk event ini.")}

      {:error, :rate_limited} ->
        {:noreply,
         put_flash(socket, :error, "Terlalu banyak permintaan. Silakan coba lagi nanti.")}

      {:error, :event_full} ->
        {:noreply, put_flash(socket, :error, "Kuota event sudah penuh.")}

      {:error, :registration_closed} ->
        {:noreply,
         socket
         |> assign(:registration_open, false)
         |> put_flash(:error, "Pendaftaran untuk event ini sudah ditutup.")}

      {:error, :event_not_found} ->
        {:noreply, put_flash(socket, :error, "Event tidak ditemukan.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Gagal mendaftar, coba lagi.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="relative min-h-screen">
        <div class="pointer-events-none absolute inset-x-0 top-0 h-[30rem] bg-gradient-to-b from-primary/10 via-secondary/5 to-transparent" />

        <div class="relative mx-auto w-full max-w-6xl px-4 pb-16 pt-6 sm:px-6 lg:px-8">
          <.breadcrumbs trail={[{"Beranda", "/"}, {"Event", "/events"}, {@event.title, nil}]} />

          <%!-- Hero --%>
          <section class="mt-4 overflow-hidden rounded-3xl border border-base-300/60 bg-base-100 shadow-[0_24px_60px_-32px_rgba(15,23,42,0.35)]">
            <%= if @event.cover_image_url do %>
              <div id="event-cover" class="flex items-center justify-center bg-base-200/50">
                <button
                  type="button"
                  id="cover-image-button"
                  phx-click="open_cover_modal"
                  class="group relative w-full cursor-zoom-in focus:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                  aria-label="Perbesar gambar sampul"
                >
                  <img
                    src={asset_url(@event.cover_image_url)}
                    alt={@event.title}
                    class="max-h-[26rem] w-full object-contain"
                  />
                  <span class="pointer-events-none absolute bottom-3 right-3 inline-flex items-center gap-1.5 rounded-full bg-black/55 px-3 py-1.5 text-xs font-medium text-white opacity-0 backdrop-blur-sm transition group-hover:opacity-100">
                    <.icon name="hero-arrows-pointing-out" class="size-3.5" /> Perbesar
                  </span>
                </button>
              </div>
            <% else %>
              <div class="relative h-36 overflow-hidden bg-gradient-to-br from-primary/25 via-secondary/20 to-accent/20 sm:h-44">
                <div class="absolute -left-10 -top-12 size-40 rounded-full bg-white/25 blur-2xl" />
                <div class="absolute -bottom-20 right-4 size-56 rounded-full bg-primary/25 blur-3xl" />
                <div class="relative flex h-full items-center justify-center">
                  <.icon name="hero-calendar-days" class="size-12 text-base-content/30" />
                </div>
              </div>
            <% end %>

            <div class="space-y-5 p-5 sm:p-7 lg:p-8">
              <div class="flex flex-wrap items-center gap-2">
                <span class="inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
                  <.icon name="hero-sparkles" class="size-3.5" />
                  {to_label(@event.event_type)}
                </span>
                <span class="inline-flex items-center rounded-full bg-base-200 px-3 py-1 text-xs font-medium text-base-content/70">
                  {to_label(@event.mode)}
                </span>
                <span
                  :if={to_label(@event.category) != ""}
                  class="inline-flex items-center rounded-full bg-base-200 px-3 py-1 text-xs font-medium text-base-content/70"
                >
                  {to_label(@event.category)}
                </span>
                <%= if @event.is_paid do %>
                  <span class="inline-flex items-center gap-1 rounded-full bg-warning/15 px-3 py-1 text-xs font-semibold text-warning">
                    <.icon name="hero-ticket" class="size-3.5" /> Berbayar
                  </span>
                <% else %>
                  <span class="inline-flex items-center gap-1 rounded-full bg-success/15 px-3 py-1 text-xs font-semibold text-success">
                    <.icon name="hero-gift" class="size-3.5" /> Gratis
                  </span>
                <% end %>
                <%= if @registration_state == :canceled do %>
                  <span class="inline-flex items-center gap-1 rounded-full bg-error/15 px-3 py-1 text-xs font-semibold text-error">
                    <.icon name="hero-x-circle" class="size-3.5" /> Event Dibatalkan
                  </span>
                <% end %>
              </div>

              <div class="space-y-2">
                <h1 class="text-balance text-3xl font-bold leading-tight tracking-tight text-base-content sm:text-4xl lg:text-[2.6rem]">
                  {@event.title}
                </h1>
                <p class="flex flex-wrap items-center gap-x-1.5 gap-y-1 text-sm text-base-content/70">
                  <.icon name="hero-building-office-2" class="size-4 text-base-content/50" />
                  <span>Diselenggarakan oleh</span>
                  <%= if @host_org do %>
                    <.link
                      navigate={"/orgs/#{@host_org.slug}"}
                      class="font-semibold text-base-content underline-offset-4 transition hover:text-primary hover:underline"
                    >
                      {@host_org.name}
                    </.link>
                    <%= if @host_user do %>
                      <span class="text-base-content/40">·</span>
                      <%= if @host_user.username do %>
                        <.link
                          navigate={"/u/#{@host_user.username}"}
                          class="text-base-content/80 underline-offset-4 transition hover:text-primary hover:underline"
                        >
                          {host_person_name(@host_user)}
                        </.link>
                      <% else %>
                        <span class="text-base-content/80">{host_person_name(@host_user)}</span>
                      <% end %>
                    <% end %>
                  <% else %>
                    <%= cond do %>
                      <% @host_user && @host_user.username -> %>
                        <.link
                          navigate={"/u/#{@host_user.username}"}
                          class="font-semibold text-base-content underline-offset-4 transition hover:text-primary hover:underline"
                        >
                          {host_person_name(@host_user)}
                        </.link>
                      <% @host_user -> %>
                        <span class="font-semibold text-base-content">{host_person_name(@host_user)}</span>
                      <% true -> %>
                        <span>Penyelenggara</span>
                    <% end %>
                  <% end %>
                </p>
              </div>

              <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
                <.meta_tile
                  icon="hero-play-circle"
                  label="Mulai"
                  value={format_datetime(@event.starts_at, @event.timezone)}
                />
                <.meta_tile
                  icon="hero-stop-circle"
                  label="Selesai"
                  value={format_datetime(@event.ends_at, @event.timezone)}
                />
                <.meta_tile icon="hero-map-pin" label="Lokasi" value={venue_text(@event)} />
                <.meta_tile icon="hero-users" label="Kapasitas" value={quota_text(@event)} />
              </div>
            </div>
          </section>

          <div class="mt-6 grid grid-cols-1 items-start gap-6 lg:grid-cols-3">
            <%!-- Main content --%>
            <section class="order-last space-y-6 lg:order-none lg:col-span-2">
              <article class="rounded-3xl border border-base-300/60 bg-base-100 p-6 sm:p-7">
                <h2 class="flex items-center gap-2 text-sm font-semibold uppercase tracking-wide text-base-content/60">
                  <.icon name="hero-document-text" class="size-4 text-primary" /> Tentang Event
                </h2>
                <div class="mt-3 whitespace-pre-line text-sm leading-relaxed text-base-content/85">
                  {@event.description || "Penyelenggara belum menambahkan deskripsi untuk event ini."}
                </div>
              </article>

              <article class="rounded-3xl border border-base-300/60 bg-base-100 p-6 sm:p-7">
                <h2 class="flex items-center gap-2 text-sm font-semibold uppercase tracking-wide text-base-content/60">
                  <.icon name="hero-information-circle" class="size-4 text-primary" /> Detail Event
                </h2>
                <dl class="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2">
                  <div class="flex items-center justify-between gap-3 rounded-2xl bg-base-200/50 px-4 py-3">
                    <dt class="text-[11px] font-medium uppercase tracking-wide text-base-content/50">
                      Jenis
                    </dt>
                    <dd class="text-sm font-semibold text-base-content">
                      {to_label(@event.event_type)}
                    </dd>
                  </div>
                  <div class="flex items-center justify-between gap-3 rounded-2xl bg-base-200/50 px-4 py-3">
                    <dt class="text-[11px] font-medium uppercase tracking-wide text-base-content/50">
                      Mode
                    </dt>
                    <dd class="text-sm font-semibold text-base-content">{to_label(@event.mode)}</dd>
                  </div>
                  <div class="flex items-center justify-between gap-3 rounded-2xl bg-base-200/50 px-4 py-3">
                    <dt class="text-[11px] font-medium uppercase tracking-wide text-base-content/50">
                      Kategori
                    </dt>
                    <dd class="text-sm font-semibold text-base-content">
                      {to_label(@event.category)}
                    </dd>
                  </div>
                  <div class="flex items-center justify-between gap-3 rounded-2xl bg-base-200/50 px-4 py-3">
                    <dt class="text-[11px] font-medium uppercase tracking-wide text-base-content/50">
                      Status
                    </dt>
                    <dd class="text-sm font-semibold text-base-content">
                      {to_label(@event.status)}
                    </dd>
                  </div>
                </dl>
              </article>

              <%= if @broadcasts != [] do %>
                <article class="rounded-3xl border border-base-300/60 bg-base-100 p-6 sm:p-7">
                  <h2 class="flex items-center gap-2 text-sm font-semibold uppercase tracking-wide text-base-content/60">
                    <.icon name="hero-megaphone" class="size-4 text-primary" /> Pengumuman
                  </h2>
                  <div class="mt-4 space-y-3">
                    <%= for broadcast <- @broadcasts do %>
                      <div class="rounded-2xl border border-base-200 bg-base-200/30 p-4">
                        <%= if broadcast.title && broadcast.title != "" do %>
                          <p class="text-sm font-semibold text-base-content">{broadcast.title}</p>
                        <% end %>
                        <div class="prose prose-sm mt-1 max-w-none text-sm text-base-content/85">
                          {Markdown.to_html(broadcast.body)}
                        </div>
                        <p class="mt-2 text-[10px] text-base-content/40">
                          {format_optional_datetime(broadcast.inserted_at, @event.timezone)}
                        </p>
                      </div>
                    <% end %>
                  </div>
                </article>
              <% end %>
            </section>

            <%!-- Registration card --%>
            <aside class="order-first space-y-4 lg:sticky lg:top-6 lg:order-last">
              <div class="overflow-hidden rounded-3xl border border-base-300/60 bg-base-100 shadow-[0_20px_50px_-32px_rgba(15,23,42,0.4)]">
                <div class="bg-gradient-to-br from-primary/10 via-secondary/10 to-transparent px-5 py-5 sm:px-6">
                  <p class="text-[11px] font-semibold uppercase tracking-[0.18em] text-base-content/50">
                    Biaya Pendaftaran
                  </p>
                  <p class="mt-1 text-3xl font-bold tracking-tight">
                    <%= if @event.is_paid do %>
                      <span class="text-primary">Rp {format_idr(@event.price_idr || 0)}</span>
                    <% else %>
                      <span class="text-success">Gratis</span>
                    <% end %>
                  </p>
                  <p class="mt-1 text-xs text-base-content/60">{quota_text(@event)}</p>
                </div>

                <div class="space-y-4 px-5 py-5 sm:px-6">
                  <%= if @event.max_attendees && @event.max_attendees > 0 do %>
                    <% pct = quota_percent(@event) %>
                    <div class="space-y-1.5">
                      <div class="flex items-center justify-between text-xs text-base-content/60">
                        <span class="font-medium text-base-content/80">Kuota terisi</span>
                        <span>{@event.registration_count || 0} / {@event.max_attendees}</span>
                      </div>
                      <div class="h-2 overflow-hidden rounded-full bg-base-200">
                        <div
                          class={[
                            "h-full rounded-full transition-all duration-500",
                            pct >= 90 && "bg-error",
                            pct < 90 && "bg-gradient-to-r from-primary to-secondary"
                          ]}
                          style={"width: #{pct}%"}
                        />
                      </div>
                    </div>
                  <% end %>

                  <dl class="space-y-2 rounded-2xl bg-base-200/40 p-4 text-xs">
                    <div class="flex items-start justify-between gap-3">
                      <dt class="text-base-content/50">Pendaftaran dibuka</dt>
                      <dd class="text-right font-medium text-base-content/80">
                        {format_optional_datetime(@event.registration_opens_at, @event.timezone)}
                      </dd>
                    </div>
                    <div class="flex items-start justify-between gap-3">
                      <dt class="text-base-content/50">Pendaftaran ditutup</dt>
                      <dd class="text-right font-medium text-base-content/80">
                        {format_optional_datetime(@event.registration_closes_at, @event.timezone)}
                      </dd>
                    </div>
                  </dl>

                  <%!-- Registration form --%>
                  <%= if @show_registration_form do %>
                    <div
                      id="registration-form-panel"
                      class="space-y-4 rounded-2xl border border-primary/30 bg-primary/5 p-4"
                    >
                      <p class="flex items-center gap-2 text-sm font-semibold text-base-content">
                        <.icon name="hero-pencil-square" class="size-4 text-primary" />
                        Formulir Pendaftaran
                      </p>
                      <div class="rounded-xl bg-base-100/80 px-4 py-3 text-sm">
                        <p class="font-medium text-base-content">{@event.title}</p>
                        <%= if @event.is_paid do %>
                          <p class="text-base-content/60">
                            Rp {format_idr(@event.price_idr || 0)}
                          </p>
                        <% end %>
                      </div>

                      <.form for={%{}} phx-submit="submit_registration" class="space-y-3">
                        <label class="block">
                          <span class="mb-1 block text-xs font-medium text-base-content/70">
                            Nama lengkap
                          </span>
                          <input
                            type="text"
                            name="registration[name]"
                            value={@prefill_name}
                            class="input input-bordered w-full rounded-xl"
                            placeholder="Nama lengkap Anda"
                            required
                          />
                        </label>
                        <label class="block">
                          <span class="mb-1 block text-xs font-medium text-base-content/70">
                            Email
                          </span>
                          <input
                            type="email"
                            name="registration[email]"
                            value={@prefill_email}
                            class="input input-bordered w-full rounded-xl"
                            placeholder="email@contoh.com"
                            required
                          />
                        </label>
                        <label class="block">
                          <span class="mb-1 block text-xs font-medium text-base-content/70">
                            No. HP / WhatsApp
                          </span>
                          <input
                            type="text"
                            name="registration[phone]"
                            value={@prefill_phone}
                            class="input input-bordered w-full rounded-xl"
                            placeholder="Opsional"
                          />
                        </label>
                        <label class="flex cursor-pointer items-start gap-2">
                          <input
                            type="checkbox"
                            name="registration[consent]"
                            value="true"
                            class="checkbox checkbox-primary checkbox-sm mt-0.5"
                            required
                          />
                          <span class="text-xs text-base-content/70">
                            Saya menyetujui pemrosesan data pribadi untuk keperluan event ini.
                          </span>
                        </label>

                        <%= if @event.is_paid do %>
                          <p class="text-sm text-base-content/70">
                            Pendaftaran Anda tercatat menunggu pembayaran — selesaikan
                            pembayaran online setelah ini untuk mengamankan slot Anda.
                          </p>
                        <% end %>

                        <div class="flex gap-2">
                          <button
                            type="submit"
                            class="flex-1 rounded-xl bg-gradient-to-r from-primary to-secondary px-4 py-2 text-sm font-semibold text-primary-content shadow-lg shadow-primary/20 transition hover:brightness-105"
                          >
                            Kirim Pendaftaran
                          </button>
                          <button
                            type="button"
                            phx-click="cancel_registration_form"
                            class="flex-1 rounded-xl bg-base-200 px-4 py-2 text-sm font-semibold text-base-content transition hover:bg-base-300"
                          >
                            Batal
                          </button>
                        </div>
                      </.form>
                    </div>
                  <% else %>
                    <div id="registration-cta" class="space-y-3">
                      <%= if @event.status in [:canceled, :registration_closed] do %>
                        <span class="inline-flex w-full items-center justify-center rounded-xl bg-base-200 px-4 py-3 text-sm font-semibold text-base-content">
                          Pendaftaran Ditutup
                        </span>
                      <% else %>
                        <%= cond do %>
                          <% @registration != nil and @registration.status == :approved -> %>
                            <div class="space-y-1 text-center">
                              <span class="inline-flex w-full items-center justify-center gap-1 rounded-xl bg-success/15 px-4 py-3 text-sm font-semibold text-success">
                                <.icon name="hero-check-circle" class="size-4" /> Disetujui
                              </span>
                              <p class="text-xs text-base-content/50">
                                Kode: {@registration.registration_code}
                              </p>
                            </div>
                          <% @registration != nil and @registration.status == :pending and
                               @event.is_paid and is_nil(@registration.paid_at) -> %>
                            <div class="space-y-1 text-center">
                              <span class="inline-flex w-full items-center justify-center gap-1 rounded-xl bg-warning/15 px-4 py-3 text-sm font-semibold text-warning">
                                <.icon name="hero-clock" class="size-4" /> Menunggu Pembayaran
                              </span>
                              <p class="text-xs text-base-content/50">
                                Selesaikan pembayaran untuk mengamankan slot Anda.
                              </p>
                            </div>
                          <% @registration != nil and @registration.status == :pending -> %>
                            <div class="space-y-1 text-center">
                              <span class="inline-flex w-full items-center justify-center gap-1 rounded-xl bg-warning/15 px-4 py-3 text-sm font-semibold text-warning">
                                <.icon name="hero-clock" class="size-4" /> Menunggu Konfirmasi
                              </span>
                              <p class="text-xs text-base-content/50">
                                Pendaftaran Anda sedang ditinjau oleh penyelenggara.
                              </p>
                            </div>
                          <% @registration != nil and @registration.status == :waitlisted -> %>
                            <div class="space-y-1 text-center">
                              <span class="inline-flex w-full items-center justify-center gap-1 rounded-xl bg-info/15 px-4 py-3 text-sm font-semibold text-info">
                                <.icon name="hero-queue-list" class="size-4" /> Dalam Daftar Tunggu
                              </span>
                              <p class="text-xs text-base-content/50">
                                Anda akan dikonfirmasi jika ada slot tersedia.
                              </p>
                            </div>
                          <% @registration != nil and @registration.status == :rejected -> %>
                            <div class="space-y-1 text-center">
                              <span class="inline-flex w-full items-center justify-center gap-1 rounded-xl bg-error/15 px-4 py-3 text-sm font-semibold text-error">
                                <.icon name="hero-x-circle" class="size-4" /> Pendaftaran Ditolak
                              </span>
                              <p class="text-xs text-base-content/50">
                                Hubungi penyelenggara untuk informasi lebih lanjut.
                              </p>
                            </div>
                          <% @registration != nil and @registration.status == :canceled -> %>
                            <span class="inline-flex w-full items-center justify-center gap-1 rounded-xl bg-base-200 px-4 py-3 text-sm font-semibold text-base-content/60">
                              <.icon name="hero-x-mark" class="size-4" /> Dibatalkan
                            </span>
                          <% @registration != nil -> %>
                            <span class="inline-flex w-full items-center justify-center rounded-xl bg-secondary/15 px-4 py-3 text-sm font-semibold text-secondary">
                              Sudah Terdaftar
                            </span>
                          <% @registration_open != true -> %>
                            <span class="inline-flex w-full items-center justify-center rounded-xl bg-base-200 px-4 py-3 text-sm font-semibold text-base-content">
                              <%= case @registration_state do %>
                                <% :full -> %>
                                  Kuota Penuh
                                <% :closed -> %>
                                  Pendaftaran Ditutup
                                <% :canceled -> %>
                                  Event Dibatalkan
                                <% :finished -> %>
                                  Event Telah Selesai
                                <% _ -> %>
                                  Pendaftaran Belum Dibuka
                              <% end %>
                            </span>
                          <% is_nil(@user_id) -> %>
                            <%!-- Guest-friendly: register without an account; login is a quiet option. --%>
                            <.link
                              navigate={"/events/#{@event.slug}/register"}
                              class="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-primary to-secondary px-4 py-3 text-sm font-semibold text-primary-content shadow-lg shadow-primary/25 transition hover:brightness-105"
                            >
                              Daftar Sekarang <.icon name="hero-arrow-right" class="size-4" />
                            </.link>
                            <.link
                              navigate={"/login?return_to=/events/#{@event.slug}/register"}
                              class="block text-center text-xs text-base-content/50 link link-hover"
                            >
                              Punya akun Curatorian? Masuk agar pendaftaran tersimpan di akun Anda
                            </.link>
                          <% has_registration_questions?(@event) -> %>
                            <.link
                              navigate={"/events/#{@event.slug}/register"}
                              class="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-primary to-secondary px-4 py-3 text-sm font-semibold text-primary-content shadow-lg shadow-primary/25 transition hover:brightness-105"
                            >
                              Daftar Sekarang <.icon name="hero-arrow-right" class="size-4" />
                            </.link>
                          <% true -> %>
                            <button
                              phx-click="register"
                              class="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-primary to-secondary px-4 py-3 text-sm font-semibold text-primary-content shadow-lg shadow-primary/25 transition hover:brightness-105"
                            >
                              Daftar Sekarang <.icon name="hero-arrow-right" class="size-4" />
                            </button>
                        <% end %>

                        <%!-- Payment CTA for registered users of paid events --%>
                        <%= if @event.is_paid and @registration != nil and is_nil(@registration.paid_at) do %>
                          <div class="border-t border-base-200 pt-3">
                            <button
                              phx-click="start_payment"
                              class="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-warning/90 px-4 py-3 text-sm font-semibold text-warning-content transition hover:brightness-95"
                            >
                              <.icon name="hero-credit-card" class="size-4" /> Bayar Sekarang
                            </button>
                            <p class="mt-1 text-center text-xs text-base-content/50">
                              Selesaikan pembayaran online untuk event ini.
                            </p>
                          </div>
                        <% end %>

                        <%!-- Everything an approved participant needs, right here --%>
                        <%= if @registration != nil and @registration.status == :approved do %>
                          <div
                            id="participant-access"
                            class="space-y-3 border-t border-base-200 pt-4"
                          >
                            <p class="text-[11px] font-semibold uppercase tracking-[0.18em] text-base-content/50">
                              Akses Peserta
                            </p>

                            <%= if @participant.join_url do %>
                              <a
                                href={@participant.join_url}
                                target="_blank"
                                rel="noopener noreferrer"
                                class="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-primary px-4 py-3 text-sm font-semibold text-primary-content shadow-lg shadow-primary/20 transition hover:brightness-105"
                              >
                                <.icon name="hero-video-camera" class="size-4" /> Gabung Sekarang
                              </a>
                            <% end %>

                            <%= if @participant.venue do %>
                              <p class="flex items-start gap-1.5 text-xs text-base-content/70">
                                <.icon
                                  name="hero-map-pin"
                                  class="mt-0.5 size-3.5 shrink-0 text-base-content/50"
                                />
                                <span>
                                  {@participant.venue}
                                  <%= if @participant.venue_maps_url do %>
                                    ·
                                    <a
                                      href={@participant.venue_maps_url}
                                      target="_blank"
                                      rel="noopener noreferrer"
                                      class="text-primary hover:underline"
                                    >
                                      Peta
                                    </a>
                                  <% end %>
                                </span>
                              </p>
                            <% end %>

                            <%= if @participant.self_checkin_active? or @participant.checked_in_at do %>
                              <div class="space-y-1 rounded-2xl border border-base-200 bg-base-200/30 p-3 text-center">
                                <%= if @participant.checked_in_at do %>
                                  <span class="inline-flex items-center gap-1.5 text-xs font-semibold text-success">
                                    <.icon name="hero-check-circle" class="size-4" />
                                    Anda sudah check-in
                                  </span>
                                <% else %>
                                  <button
                                    type="button"
                                    phx-click="self_check_in"
                                    class="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-success px-4 py-2.5 text-sm font-semibold text-success-content transition hover:brightness-105"
                                  >
                                    <.icon name="hero-hand-raised" class="size-4" /> Check-in Sekarang
                                  </button>
                                  <p class="text-[11px] text-base-content/50">
                                    Tanpa menunggu penyelenggara — selama event berlangsung.
                                  </p>
                                <% end %>
                              </div>
                            <% end %>

                            <%= if @participant.qr_data_uri do %>
                              <div class="rounded-2xl border border-base-200 bg-base-200/30 p-3 text-center">
                                <img
                                  id="participant-qr"
                                  src={@participant.qr_data_uri}
                                  alt="QR check-in"
                                  class="mx-auto size-36"
                                />
                                <p class="mt-1 text-[11px] text-base-content/50">
                                  Tunjukkan QR ini ke penyelenggara untuk check-in.
                                </p>
                              </div>
                            <% end %>

                            <%= if @participant.session_code_active? do %>
                              <div class="space-y-2 rounded-2xl border border-primary/30 bg-primary/5 p-3">
                                <p class="text-xs font-semibold text-base-content">Kode Sesi</p>
                                <.form for={%{}} phx-submit="submit_code" class="flex gap-2">
                                  <input
                                    type="text"
                                    name="code"
                                    value={@code_input}
                                    class="input input-bordered input-sm flex-1 font-mono uppercase"
                                    placeholder="ABC123"
                                    maxlength="12"
                                    required
                                  />
                                  <button type="submit" class="btn btn-primary btn-sm">
                                    Kirim
                                  </button>
                                </.form>
                                <p :if={@code_error} class="text-xs text-error">{@code_error}</p>
                                <p
                                  :if={@participant.checkpoint_count > 0}
                                  class="text-[11px] text-base-content/50"
                                >
                                  Sesi tercatat: {@participant.checkpoint_count}
                                </p>
                              </div>
                            <% end %>

                            <%= if @participant.certificate do %>
                              <.link
                                navigate={~p"/certificates/#{@participant.certificate.id}"}
                                class="inline-flex w-full items-center justify-center gap-2 rounded-xl border border-success/40 bg-success/10 px-4 py-3 text-sm font-semibold text-success transition hover:bg-success/15"
                              >
                                <.icon name="hero-academic-cap" class="size-4" /> Lihat Sertifikat
                              </.link>
                            <% end %>

                            <%= if @participant.materials_url do %>
                              <a
                                href={@participant.materials_url}
                                target="_blank"
                                rel="noopener noreferrer"
                                class="inline-flex w-full items-center justify-center gap-2 rounded-xl border border-base-300 bg-base-100 px-4 py-3 text-sm font-semibold text-base-content transition hover:bg-base-200"
                              >
                                <.icon name="hero-folder-open" class="size-4" /> Materi Pembelajaran
                              </a>
                            <% end %>

                            <%= if @participant.participant_url do %>
                              <.link
                                navigate={@participant.participant_url}
                                class="block text-center text-xs text-base-content/50 link link-hover"
                              >
                                Buka halaman peserta (QR, kode sesi, sertifikat)
                              </.link>
                            <% end %>
                          </div>
                        <% end %>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            </aside>
          </div>
        </div>
      </div>

      <%!-- Cover lightbox --%>
      <%= if @cover_modal_open and @event.cover_image_url do %>
        <div
          id="cover-modal"
          class="fixed inset-0 z-[100] flex items-center justify-center bg-black/80 p-4 backdrop-blur-sm"
          phx-click="close_cover_modal"
          phx-click-away="close_cover_modal"
          role="dialog"
          aria-modal="true"
          aria-label={@event.title}
        >
          <button
            type="button"
            phx-click="close_cover_modal"
            class="absolute right-4 top-4 inline-flex size-10 items-center justify-center rounded-full bg-white/15 text-white transition hover:bg-white/25"
            aria-label="Tutup gambar"
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
          <img
            src={asset_url(@event.cover_image_url)}
            alt={@event.title}
            class="max-h-[90vh] max-w-[95vw] rounded-lg object-contain shadow-2xl"
          />
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :value, :string, required: true

  defp meta_tile(assigns) do
    ~H"""
    <div class="flex items-start gap-3 rounded-2xl border border-base-300/50 bg-base-200/30 p-3.5">
      <span class="flex size-9 shrink-0 items-center justify-center rounded-xl bg-base-100 text-primary shadow-sm">
        <.icon name={@icon} class="size-4" />
      </span>
      <div class="min-w-0">
        <p class="text-[11px] font-medium uppercase tracking-wide text-base-content/50">{@label}</p>
        <p class="text-sm font-semibold leading-snug text-base-content">{@value}</p>
      </div>
    </div>
    """
  end

  # Everything the event page needs to serve a registered participant:
  # join link, venue, personal QR, session-code state, certificate, materials.
  defp participant_assigns(nil, _event) do
    %{
      participant_url: nil,
      qr_data_uri: nil,
      join_url: nil,
      certificate: nil,
      checked_in_at: nil,
      self_checkin_active?: false,
      checkpoint_count: 0,
      session_code_active?: false,
      materials_url: nil,
      venue: nil,
      venue_maps_url: nil
    }
  end

  defp participant_assigns(registration, event) do
    approved? = registration.status == :approved
    attendance = if approved?, do: Public.get_attendance_for_registration(registration.id)

    participant_url =
      if is_binary(registration.token) and registration.token != "" do
        "/r/#{registration.token}"
      end

    %{
      participant_url: participant_url,
      qr_data_uri:
        if(approved? and participant_url, do: qr_data_uri(url(~p"/r/#{registration.token}"))),
      join_url:
        if(
          approved? and event.mode in [:online, :hybrid] and
            is_binary(event.meeting_url) and event.meeting_url != "",
          do: event.meeting_url
        ),
      certificate: Public.get_certificate_for_registration(registration.id),
      checked_in_at: attendance && attendance.checked_in_at,
      self_checkin_active?:
        approved? and event.attendance_mode == "self_checkin" and event.status != :canceled and
          is_nil(attendance) and event_window_open?(event),
      checkpoint_count: length(Public.list_checkpoint_records(registration.id)),
      session_code_active?:
        approved? and event.status != :canceled and
          event.attendance_mode in ["session_code", "both"] and
          event_window_open?(event),
      materials_url:
        if(approved? and is_binary(event.material_url) and event.material_url != "",
          do: event.material_url
        ),
      venue: venue_label(event),
      venue_maps_url: event.venue_maps_url
    }
  end

  defp event_window_open?(event) do
    now = DateTime.utc_now()
    after_start? = is_nil(event.starts_at) or DateTime.compare(now, event.starts_at) != :lt
    before_end? = is_nil(event.ends_at) or DateTime.compare(now, event.ends_at) != :gt
    after_start? and before_end?
  end

  defp venue_label(event) do
    if event.mode in [:offline, :hybrid] do
      city = [event.venue_city, event.venue_province] |> Enum.reject(&is_nil/1) |> Enum.join(", ")

      [event.venue_name, event.venue_address, city]
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.join(" · ")
      |> case do
        "" -> nil
        label -> label
      end
    end
  end

  # Server-side QR (PNG data URI). PNG avoids the invalid-SVG markup some
  # browsers refuse to render, and needs no JS hook at all.
  defp qr_data_uri(value) do
    settings = %PngSettings{scale: 8, background_color: "#ffffff", qrcode_color: "#1f2937"}

    value
    |> QRCode.create(:high)
    |> QRCode.render(:png, settings)
    |> QRCode.to_base64()
    |> case do
      {:ok, base64} -> "data:image/png;base64,#{base64}"
      _ -> nil
    end
  end

  defp event_json(event, base, cover) do
    %{
      "@context" => "https://schema.org",
      "@type" => "Event",
      "name" => event.title,
      "description" => event.description,
      "startDate" => iso_datetime(event.starts_at),
      "endDate" => iso_datetime(event.ends_at),
      "eventAttendanceMode" => attendance_mode_url(event.mode),
      # schema.org statuses: EventScheduled | EventMovedOnline | EventPostponed |
      # EventRescheduled | EventCancelled | EventOffline
      "eventStatus" => event_status_url(event.status),
      # meeting_url is gated to approved registrants — not exposed in public JSON-LD
      "location" => event_location(event),
      "image" => cover && Public.asset_url(cover),
      "url" => "#{base}/events/#{event.slug}",
      "isAccessibleForFree" => !event.is_paid
    }
    |> maybe_put_offer(event, base)
  end

  defp maybe_put_offer(json, event, base) do
    if event.is_paid do
      Map.put(json, "offers", %{
        "@type" => "Offer",
        "price" => event.price_idr || 0,
        "priceCurrency" => "IDR",
        "url" => "#{base}/events/#{event.slug}",
        "availability" =>
          if(registration_open?(event),
            do: "https://schema.org/InStock",
            else: "https://schema.org/SoldOut"
          )
      })
    else
      json
    end
  end

  defp attendance_mode_url(:online), do: "https://schema.org/OnlineEventAttendanceMode"
  defp attendance_mode_url(:hybrid), do: "https://schema.org/MixedEventAttendanceMode"
  defp attendance_mode_url(_), do: "https://schema.org/OfflineEventAttendanceMode"

  # Search engines must not advertise a canceled event as upcoming.
  # Public for testability; also reusable if JSON-LD moves to a shared module.
  def event_status_url(:canceled), do: "https://schema.org/EventCancelled"
  def event_status_url(_), do: "https://schema.org/EventScheduled"

  defp event_location(%{mode: :online}) do
    %{"@type" => "VirtualLocation"}
  end

  defp event_location(%{mode: :hybrid} = event) do
    [
      %{"@type" => "VirtualLocation"},
      venue_json(event)
    ]
  end

  defp event_location(event), do: venue_json(event)

  defp venue_json(event) do
    %{
      "@type" => "Place",
      "name" => event.venue_name,
      "address" => %{
        "@type" => "PostalAddress",
        "streetAddress" => event.venue_address,
        "addressLocality" => event.venue_city,
        "addressRegion" => event.venue_province,
        "addressCountry" => "ID"
      }
    }
  end

  defp registration_open?(event) do
    registration_state(event) == :open
  end

  # Why registration is (not) possible — drives the show-page badge copy.
  # "Pendaftaran Belum Dibuka" is only accurate before the window opens;
  # a full or closed event needs its own message.
  defp registration_state(event) do
    now = DateTime.utc_now()

    cond do
      event.status == :canceled ->
        :canceled

      event.status == :completed ->
        :finished

      event.status == :draft ->
        :unavailable

      event.registration_opens_at && DateTime.compare(now, event.registration_opens_at) == :lt ->
        :not_yet_open

      event.registration_closes_at && DateTime.compare(now, event.registration_closes_at) != :lt ->
        :closed

      event.max_attendees && event.max_attendees > 0 &&
          event.registration_count >= event.max_attendees ->
        :full

      true ->
        :open
    end
  end

  defp has_registration_questions?(event) do
    is_list(event.registration_questions) and event.registration_questions != []
  end

  defp quota_text(event) do
    if event.max_attendees && event.max_attendees > 0 do
      "#{event.registration_count || 0} dari #{event.max_attendees} peserta"
    else
      "Kuota tidak dibatasi"
    end
  end

  defp quota_percent(event) do
    if event.max_attendees && event.max_attendees > 0 do
      min(100, round((event.registration_count || 0) / event.max_attendees * 100))
    else
      0
    end
  end

  defp host_person_name(%{display_name: name}) when is_binary(name) and name != "", do: name
  defp host_person_name(%{username: username}) when is_binary(username), do: username
  defp host_person_name(_), do: "Penyelenggara"

  defp venue_text(event) do
    cond do
      event.mode == :online -> "Online"
      event.venue_city && event.venue_province -> "#{event.venue_city}, #{event.venue_province}"
      event.venue_city -> event.venue_city
      true -> "-"
    end
  end

  defp format_datetime(nil, _tz), do: "-"
  defp format_datetime(dt, tz), do: TimeFormat.datetime(dt, tz)

  defp format_optional_datetime(nil, _tz), do: "Tidak ditentukan"
  defp format_optional_datetime(dt, tz), do: TimeFormat.datetime_short(dt, tz)

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
  defp to_label(:reading_program), do: "Program Baca"
  defp to_label(:canceled), do: "Dibatalkan"
  defp to_label(:published), do: "Dipublikasikan"
  defp to_label(:registration_closed), do: "Pendaftaran Ditutup"
  defp to_label(:ongoing), do: "Berlangsung"
  defp to_label(:completed), do: "Selesai"
  defp to_label(_), do: ""

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
