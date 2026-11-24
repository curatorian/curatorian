defmodule CuratorianWeb.Public.ParticipantPageLive do
  @moduledoc """
  Participant page at `/r/:token` — accessible without login.

  The token is the participant's credential. Shows event details, registration
  status, personal QR code (for organizer scanning), session code entry (when
  active), and the certificate download link (when issued).
  """

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case Public.get_registration_by_token(token) do
      {registration, event} ->
        # A logged-in visitor opening a guest registration's page that
        # matches their account email claims it (Google-Form guests who
        # later signed up). Fire and forget.
        current_scope = socket.assigns[:current_scope]

        if current_scope && current_scope.user do
          Public.claim_guest_registrations(current_scope.user.id, current_scope.user.email)
        end

        checkpoint_records = Public.list_checkpoint_records(registration.id)

        certificate =
          Public.get_certificate_for_registration(registration.id)

        # #12: the join link was previously only in the 1h reminder email.
        # Approved participants of online/hybrid events get it on their
        # participant page.
        join_url =
          if registration.status == :approved and event.mode in [:online, :hybrid] and
               is_binary(event.meeting_url) and event.meeting_url != "" do
            event.meeting_url
          end

        {:ok,
         socket
         |> assign(:page_title, "#{event.title} — Peserta")
         |> assign(:registration, registration)
         |> assign(:event, event)
         |> assign(:join_url, join_url)
         |> assign(
           :awaiting_payment,
           event.is_paid and is_nil(registration.paid_at)
         )
         |> assign(:checkpoint_records, checkpoint_records)
         |> assign(:certificate, certificate)
         |> assign(:code_input, "")
         |> assign(:code_error, nil)
         |> assign(:noindex, true)}

      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Tautan peserta tidak valid atau sudah kedaluwarsa.")
         |> push_navigate(to: "/events")}
    end
  end

  @impl true
  def handle_event("start_payment", _params, socket) do
    %{event: event, registration: registration} = socket.assigns

    # Guests pay with their registration token; account registrations are
    # authorized by the logged-in user (nil here is fine — the token is the
    # credential on this page).
    identity_opts = [registration_token: registration.token]

    case Curatorian.EventPayments.start_payment(event.id, registration.id, nil, identity_opts) do
      {:ok, %{redirect_url: redirect_url}} ->
        {:noreply, redirect(socket, external: redirect_url)}

      {:error, _reason} ->
        {:noreply,
         put_flash(
           socket,
           :warning,
           "Pembayaran online sedang tidak tersedia. Penyelenggara akan menghubungi Anda untuk penyelesaian pembayaran."
         )}
    end
  end

  @impl true
  def handle_event("submit_code", %{"code" => code}, socket) do
    code = String.upcase(String.trim(code || ""))

    if code == "" do
      {:noreply, assign(socket, :code_error, "Masukkan kode sesi.")}
    else
      case Public.record_checkpoint_attendance(socket.assigns.registration.id, code) do
        {:ok, _record} ->
          checkpoint_records = Public.list_checkpoint_records(socket.assigns.registration.id)

          {:noreply,
           socket
           |> assign(:checkpoint_records, checkpoint_records)
           |> assign(:code_input, "")
           |> assign(:code_error, nil)
           |> put_flash(:info, "Kehadiran tercatat!")}

        {:error, :invalid_code} ->
          {:noreply, assign(socket, :code_error, "Kode tidak valid atau sudah kedaluwarsa.")}

        {:error, :already_recorded} ->
          {:noreply, assign(socket, :code_error, "Kehadiran sudah tercatat untuk sesi ini.")}

        {:error, :rate_limited} ->
          {:noreply,
           assign(socket, :code_error, "Terlalu banyak percobaan. Silakan coba lagi nanti.")}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto py-8 px-4 space-y-6">
        <%!-- Header --%>
        <div class="text-center">
          <p class="text-xs uppercase tracking-widest text-base-content/50 mb-1">Peserta Event</p>
          <h1 class="text-2xl font-bold text-base-content">{@event.title}</h1>
          <p class="text-sm text-base-content/60 mt-1">
            {format_dt(@event.starts_at)} — {format_dt(@event.ends_at)}
          </p>
        </div>

        <%!-- Status --%>
        <div class="bg-base-100 border border-base-300 rounded-2xl p-5 text-center">
          <%= case @registration.status do %>
            <% :approved -> %>
              <span class="inline-flex items-center gap-1 px-4 py-2 rounded-xl bg-success/15 text-success font-semibold text-sm">
                <.icon name="hero-check-circle" class="size-4" /> Pendaftaran Disetujui
              </span>
            <% :pending -> %>
              <%= if @awaiting_payment do %>
                <span class="inline-flex items-center gap-1 px-4 py-2 rounded-xl bg-warning/15 text-warning font-semibold text-sm">
                  <.icon name="hero-clock" class="size-4" /> Menunggu Pembayaran
                </span>
                <p class="text-xs text-base-content/50 mt-1">
                  Selesaikan pembayaran untuk mengamankan slot Anda.
                </p>
                <button
                  phx-click="start_payment"
                  class="btn btn-warning btn-sm w-full mt-3 gap-1"
                >
                  <.icon name="hero-credit-card" class="size-4" /> Bayar Sekarang
                </button>
              <% else %>
                <span class="inline-flex items-center gap-1 px-4 py-2 rounded-xl bg-warning/15 text-warning font-semibold text-sm">
                  <.icon name="hero-clock" class="size-4" /> Menunggu Konfirmasi
                </span>
                <p class="text-xs text-base-content/50 mt-1">
                  Penyelenggara akan mengkonfirmasi pendaftaran Anda.
                </p>
              <% end %>
            <% :waitlisted -> %>
              <span class="inline-flex items-center gap-1 px-4 py-2 rounded-xl bg-info/15 text-info font-semibold text-sm">
                <.icon name="hero-queue-list" class="size-4" /> Daftar Tunggu
              </span>
            <% _ -> %>
              <span class="badge badge-ghost">{@registration.status}</span>
          <% end %>

          <p class="font-mono text-lg font-bold text-primary mt-3 tracking-wider">
            {@registration.registration_code}
          </p>
        </div>

        <%!-- Join link (approved + online/hybrid only) --%>
        <%= if @join_url do %>
          <div class="bg-base-100 border border-primary/30 rounded-2xl p-5 text-center">
            <p class="text-sm font-semibold text-base-content mb-2">Bergabung ke Sesi</p>
            <a
              href={@join_url}
              target="_blank"
              rel="noopener noreferrer"
              class="btn btn-primary w-full gap-2"
            >
              <.icon name="hero-video-camera" class="size-4" /> Buka Tautan Bergabung
            </a>
            <p class="text-xs text-base-content/50 mt-2 break-all">
              {@join_url}
            </p>
          </div>
        <% end %>

        <%!-- QR Code --%>
        <div class="bg-base-100 border border-base-300 rounded-2xl p-6 text-center">
          <p class="text-sm font-medium text-base-content mb-3">
            QR Check-in
          </p>
          <div
            id="participant-qr"
            class="flex justify-center"
            phx-hook=".ParticipantQr"
            data-url={url(~p"/r/#{@registration.token}")}
          >
          </div>
          <p class="text-xs text-base-content/50 mt-3">
            Tunjukkan QR ini kepada penyelenggara untuk check-in.
          </p>
        </div>

        <%!-- Session code entry --%>
        <%= if session_code_active?(@event) do %>
          <div class="bg-base-100 border border-base-300 rounded-2xl p-5 space-y-3">
            <p class="text-sm font-semibold text-base-content">Masukkan Kode Sesi</p>
            <.form for={%{}} phx-submit="submit_code" class="flex gap-2">
              <input
                type="text"
                name="code"
                value={@code_input}
                class="input input-bordered flex-1 font-mono uppercase"
                placeholder="Kode 6 karakter"
                maxlength="12"
                required
              />
              <button type="submit" class="btn btn-primary">Kirim</button>
            </.form>
            <p :if={@code_error} class="text-sm text-error">{@code_error}</p>

            <%= if @checkpoint_records != [] do %>
              <div class="text-xs text-base-content/50">
                Sesi tercatat: {length(@checkpoint_records)}
              </div>
            <% end %>
          </div>
        <% end %>

        <%!-- Certificate --%>
        <%= if @certificate do %>
          <div class="bg-base-100 border border-base-300 rounded-2xl p-5 text-center">
            <.icon name="hero-academic-cap" class="size-8 text-primary mx-auto mb-2" />
            <p class="text-sm font-semibold">{@certificate.certificate_number}</p>
            <.link
              navigate={~p"/certificates/#{@certificate.id}"}
              class="btn btn-sm btn-outline btn-primary mt-2"
            >
              Lihat Sertifikat
            </.link>
          </div>
        <% end %>

        <%!-- Event link --%>
        <div class="text-center">
          <.link navigate={~p"/events/#{@event.slug}"} class="text-sm text-primary hover:underline">
            Lihat detail event
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp session_code_active?(event) do
    event.status == :ongoing and
      event.attendance_mode in ["session_code", "both"]
  end

  defp format_dt(nil), do: "-"
  defp format_dt(dt), do: Calendar.strftime(dt, "%A, %d %B %Y, %H:%M UTC")
end
