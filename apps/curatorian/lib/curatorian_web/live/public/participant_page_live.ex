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
        checkpoint_records = Public.list_checkpoint_records(registration.id)

        certificate =
          Public.get_certificate_for_registration(registration.id)

        {:ok,
         socket
         |> assign(:page_title, "#{event.title} — Peserta")
         |> assign(:registration, registration)
         |> assign(:event, event)
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
              <span class="inline-flex items-center gap-1 px-4 py-2 rounded-xl bg-warning/15 text-warning font-semibold text-sm">
                <.icon name="hero-clock" class="size-4" /> Menunggu Konfirmasi
              </span>
              <p class="text-xs text-base-content/50 mt-1">Penyelenggara akan mengkonfirmasi pendaftaran Anda.</p>
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

        <%!-- QR Code --%>
        <div class="bg-base-100 border border-base-300 rounded-2xl p-6 text-center">
          <p class="text-sm font-medium text-base-content mb-3">
            QR Check-in
          </p>
          <div id="participant-qr" class="flex justify-center" phx-hook=".ParticipantQr" data-url={url(~p"/r/#{@registration.token}")}>
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
