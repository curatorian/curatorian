defmodule CuratorianWeb.Public.Events.CertificateLive do
  @moduledoc """
  Public certificate display and verification page.
  Shows certificate details, allows download, and provides sharing options.
  """

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  def mount(%{"id" => certificate_id}, _session, socket) do
    case Public.get_certificate(certificate_id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Sertifikat tidak ditemukan.")
         |> push_navigate(to: "/foyer")}

      certificate ->
        current_scope = socket.assigns.current_scope

        user_id =
          if current_scope && current_scope.user do
            current_scope.user.id
          end

        # Check if certificate belongs to current user or if it's public verification
        can_view =
          is_nil(certificate.voile_user_id) or
            certificate.voile_user_id == user_id or
            socket.assigns[:verification_mode]

        if can_view do
          event = Public.get_event(certificate.event_id)

          {:ok,
           socket
           |> assign(:page_title, "Sertifikat — #{certificate.event_title}")
           |> assign(:certificate, certificate)
           |> assign(:event, event)
           |> assign(:user_id, user_id)
           |> assign(:share_modal_open, false)
           |> assign(:verification_url, verification_url(certificate))}
        else
          {:ok,
           socket
           |> put_flash(:error, "Anda tidak memiliki akses ke sertifikat ini.")
           |> push_navigate(to: "/foyer")}
        end
    end
  end

  # Public verification route
  def mount(%{"token" => token}, _session, socket) do
    case Public.get_certificate_by_token(token) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Sertifikat tidak valid atau sudah dicabut.")
         |> push_navigate(to: "/events")}

      certificate ->
        event = Public.get_event(certificate.event_id)

        {:ok,
         socket
         |> assign(:page_title, "Verifikasi Sertifikat — #{certificate.event_title}")
         |> assign(:certificate, certificate)
         |> assign(:event, event)
         |> assign(:verification_mode, true)
         |> assign(:share_modal_open, false)
         |> assign(:verification_url, verification_url(certificate))}
    end
  end

  def handle_event("download", _params, socket) do
    certificate = socket.assigns.certificate

    if certificate.pdf_url do
      # Track download
      Public.increment_certificate_download(certificate.id)

      {:noreply,
       socket
       |> put_flash(:info, "Mengunduh sertifikat...")
       |> push_event("download_pdf", %{url: certificate.pdf_url})}
    else
      {:noreply, put_flash(socket, :error, "File sertifikat belum tersedia")}
    end
  end

  def handle_event("toggle_share_modal", _params, socket) do
    {:noreply, assign(socket, :share_modal_open, !socket.assigns.share_modal_open)}
  end

  def handle_event("copy_link", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Link sertifikat disalin!")
     |> push_event("copy_to_clipboard", %{text: socket.assigns.verification_url})}
  end

  defp verification_url(certificate) do
    "https://curatorian.id/certificates/verify/#{certificate.verification_token}"
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-gradient-to-br from-primary/5 via-base-200/30 to-secondary/5 py-12">
        <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
          <%!-- Header --%>
          <div class="text-center mb-8">
            <%= if assigns[:verification_mode] do %>
              <div class="inline-flex items-center gap-2 px-4 py-2 bg-success/10 text-success rounded-full mb-4">
                <.icon name="hero-check-badge" class="w-5 h-5" />
                <span class="font-semibold">Sertifikat Terverifikasi</span>
              </div>
            <% end %>

            <h1 class="text-3xl font-bold mb-2">Sertifikat Kehadiran</h1>
            <p class="text-base-content/70">{@certificate.event_title}</p>
          </div>

          <%!-- Certificate Preview Card --%>
          <div class="bg-base-100 rounded-2xl shadow-2xl overflow-hidden mb-8">
            <%!-- Certificate Image/Preview --%>
            <div class="relative bg-gradient-to-br from-primary/10 to-secondary/10 p-12 sm:p-16">
              <div class="aspect-[1.414/1] bg-white rounded-lg shadow-xl flex items-center justify-center">
                <%= if @certificate.pdf_url do %>
                  <%!-- Placeholder for certificate preview --%>
                  <div class="text-center p-8">
                    <div class="mb-6">
                      <.icon name="hero-academic-cap" class="w-20 h-20 text-primary mx-auto" />
                    </div>

                    <h2 class="text-2xl sm:text-3xl font-serif font-bold mb-4">
                      Sertifikat Penghargaan
                    </h2>

                    <p class="text-sm text-base-content/60 mb-4">Diberikan kepada</p>

                    <p class="text-xl sm:text-2xl font-bold mb-6">{@certificate.recipient_name}</p>

                    <p class="text-sm text-base-content/70 mb-4">
                      Atas partisipasi dalam
                    </p>

                    <p class="text-lg font-semibold mb-6">{@certificate.event_title}</p>

                    <div class="flex items-center justify-center gap-8 text-sm text-base-content/60">
                      <div>
                        <p class="font-semibold">Tanggal</p>
                        <p>{format_date(@certificate.event_date)}</p>
                      </div>

                      <%= if @certificate.event_duration_minutes do %>
                        <div>
                          <p class="font-semibold">Durasi</p>
                          <p>{format_duration(@certificate.event_duration_minutes)}</p>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% else %>
                  <div class="text-center">
                    <.icon
                      name="hero-document-text"
                      class="w-16 h-16 text-base-content/30 mx-auto mb-4"
                    />
                    <p class="text-base-content/50">Sedang memproses sertifikat...</p>
                  </div>
                <% end %>
              </div>

              <%!-- Certificate Number Badge --%>
              <div class="absolute top-4 right-4">
                <div class="bg-base-100/90 backdrop-blur-sm rounded-lg px-4 py-2 shadow-lg">
                  <p class="text-xs text-base-content/60">No. Sertifikat</p>
                  <p class="font-mono text-sm font-bold">{@certificate.certificate_number}</p>
                </div>
              </div>
            </div>

            <%!-- Certificate Details --%>
            <div class="p-6 sm:p-8">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                <div>
                  <h3 class="font-semibold mb-3 flex items-center gap-2">
                    <.icon name="hero-user" class="w-5 h-5 text-primary" /> Penerima
                  </h3>
                  <div class="space-y-2 text-sm">
                    <div>
                      <p class="text-base-content/60">Nama</p>
                      <p class="font-medium">{@certificate.recipient_name}</p>
                    </div>
                    <%= if @certificate.recipient_email do %>
                      <div>
                        <p class="text-base-content/60">Email</p>
                        <p class="font-medium">{@certificate.recipient_email}</p>
                      </div>
                    <% end %>
                  </div>
                </div>

                <div>
                  <h3 class="font-semibold mb-3 flex items-center gap-2">
                    <.icon name="hero-calendar" class="w-5 h-5 text-primary" /> Detail Event
                  </h3>
                  <div class="space-y-2 text-sm">
                    <div>
                      <p class="text-base-content/60">Event</p>
                      <p class="font-medium">{@certificate.event_title}</p>
                    </div>
                    <div>
                      <p class="text-base-content/60">Tanggal</p>
                      <p class="font-medium">{format_date(@certificate.event_date)}</p>
                    </div>
                    <%= if @certificate.host_name do %>
                      <div>
                        <p class="text-base-content/60">Penyelenggara</p>
                        <p class="font-medium">{@certificate.host_name}</p>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <h3 class="font-semibold mb-3 flex items-center gap-2">
                    <.icon name="hero-shield-check" class="w-5 h-5 text-primary" /> Verifikasi
                  </h3>
                  <div class="space-y-2 text-sm">
                    <div>
                      <p class="text-base-content/60">Status</p>
                      <div class="flex items-center gap-2 mt-1">
                        <%= if @certificate.is_valid do %>
                          <span class="badge badge-success badge-sm">Valid</span>
                        <% else %>
                          <span class="badge badge-error badge-sm">Dicabut</span>
                        <% end %>
                      </div>
                    </div>
                    <div>
                      <p class="text-base-content/60">Diterbitkan</p>
                      <p class="font-medium">{format_datetime(@certificate.issued_at)}</p>
                    </div>
                    <%= if @certificate.download_count && @certificate.download_count > 0 do %>
                      <div>
                        <p class="text-base-content/60">Diunduh</p>
                        <p class="font-medium">{@certificate.download_count}x</p>
                      </div>
                    <% end %>
                  </div>
                </div>

                <%!-- QR Code Placeholder --%>
                <div>
                  <h3 class="font-semibold mb-3 flex items-center gap-2">
                    <.icon name="hero-qr-code" class="w-5 h-5 text-primary" /> QR Code Verifikasi
                  </h3>
                  <div class="bg-base-200 rounded-lg p-4 flex items-center justify-center">
                    <div class="w-32 h-32 bg-white rounded flex items-center justify-center">
                      <%!-- TODO: Generate actual QR code --%>
                      <.icon name="hero-qr-code" class="w-20 h-20 text-base-content/20" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <%!-- Action Buttons --%>
          <div class="flex flex-col sm:flex-row gap-3 justify-center mb-8">
            <%= if @certificate.pdf_url do %>
              <button phx-click="download" class="btn btn-primary btn-lg">
                <.icon name="hero-arrow-down-tray" class="w-5 h-5" /> Unduh Sertifikat (PDF)
              </button>
            <% end %>

            <button phx-click="toggle_share_modal" class="btn btn-outline btn-lg">
              <.icon name="hero-share" class="w-5 h-5" /> Bagikan Sertifikat
            </button>

            <%= if @event do %>
              <.link navigate={"/events/#{@event.slug}"} class="btn btn-ghost btn-lg">
                <.icon name="hero-arrow-left" class="w-5 h-5" /> Kembali ke Event
              </.link>
            <% end %>
          </div>

          <%!-- Info Box --%>
          <div class="bg-base-100 rounded-lg p-6 text-center">
            <.icon name="hero-information-circle" class="w-8 h-8 text-info mx-auto mb-3" />
            <p class="text-sm text-base-content/70">
              Sertifikat ini dapat diverifikasi dengan mengunjungi link verifikasi atau memindai QR code.
              <br />
              <a href={@verification_url} class="link link-primary">
                {@verification_url}
              </a>
            </p>
          </div>
        </div>
      </div>

      <%!-- Share Modal --%>
      <%= if @share_modal_open do %>
        <div
          class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
          phx-click="toggle_share_modal"
        >
          <div
            class="bg-base-100 rounded-2xl max-w-md w-full p-6"
            phx-click={JS.stop_propagation()}
          >
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-xl font-bold">Bagikan Sertifikat</h3>
              <button phx-click="toggle_share_modal" class="btn btn-ghost btn-sm btn-circle">
                <.icon name="hero-x-mark" class="w-5 h-5" />
              </button>
            </div>

            <p class="text-sm text-base-content/70 mb-6">
              Bagikan pencapaian Anda di media sosial atau kirim link verifikasi ke orang lain.
            </p>

            <div class="space-y-3">
              <%!-- Social Share Buttons --%>
              <a
                href={"https://www.linkedin.com/sharing/share-offsite/?url=#{URI.encode(@verification_url)}"}
                target="_blank"
                class="btn btn-block justify-start gap-3 bg-[#0077B5] hover:bg-[#006399] text-white border-0"
              >
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" />
                </svg>
                Bagikan di LinkedIn
              </a>

              <a
                href={"https://twitter.com/intent/tweet?text=Saya%20mendapatkan%20sertifikat%20dari%20#{URI.encode(@certificate.event_title)}!&url=#{URI.encode(@verification_url)}"}
                target="_blank"
                class="btn btn-block justify-start gap-3 bg-[#1DA1F2] hover:bg-[#1a8cd8] text-white border-0"
              >
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z" />
                </svg>
                Bagikan di Twitter
              </a>

              <a
                href={"https://www.facebook.com/sharer/sharer.php?u=#{URI.encode(@verification_url)}"}
                target="_blank"
                class="btn btn-block justify-start gap-3 bg-[#1877F2] hover:bg-[#166fe5] text-white border-0"
              >
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
                </svg>
                Bagikan di Facebook
              </a>

              <div class="divider">ATAU</div>

              <%!-- Copy Link --%>
              <button phx-click="copy_link" class="btn btn-outline btn-block justify-start gap-3">
                <.icon name="hero-clipboard-document" class="w-5 h-5" /> Salin Link Verifikasi
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </Layouts.app>

    <script>
      window.addEventListener("phx:download_pdf", (e) => {
        window.open(e.detail.url, '_blank');
      });

      window.addEventListener("phx:copy_to_clipboard", (e) => {
        navigator.clipboard.writeText(e.detail.text);
      });
    </script>
    """
  end

  defp format_date(date) when is_struct(date, Date) do
    Calendar.strftime(date, "%d %B %Y")
  end

  defp format_date(_), do: "-"

  defp format_datetime(datetime) when is_struct(datetime, DateTime) do
    Calendar.strftime(datetime, "%d %B %Y, %H:%M WIB")
  end

  defp format_datetime(_), do: "-"

  defp format_duration(minutes) when is_integer(minutes) do
    cond do
      minutes < 60 -> "#{minutes} menit"
      minutes == 60 -> "1 jam"
      rem(minutes, 60) == 0 -> "#{div(minutes, 60)} jam"
      true -> "#{div(minutes, 60)} jam #{rem(minutes, 60)} menit"
    end
  end

  defp format_duration(_), do: "-"
end
