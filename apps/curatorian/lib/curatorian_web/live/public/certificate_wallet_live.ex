defmodule CuratorianWeb.Public.CertificateWalletLive do
  @moduledoc "Certificate wallet — lists all certificates for the logged-in user."

  use CuratorianWeb, :live_view

  import Ecto.Query

  alias Curatorian.Repo
  alias CuratorianWeb.Public.Events.TimeFormat

  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope

    if current_scope && current_scope.user do
      certificates = fetch_certificates(current_scope.user.id)

      {:ok,
       socket
       |> assign(:page_title, "Sertifikat Saya")
       |> assign(:certificates, certificates)}
    else
      {:ok,
       socket
       |> put_flash(:error, "Anda harus masuk untuk melihat sertifikat.")
       |> push_navigate(to: "/login")}
    end
  end

  defp fetch_certificates(user_id) do
    from(c in "event_certificates",
      join: r in "event_registrations",
      on: c.registration_id == r.id,
      join: e in "events",
      on: c.event_id == e.id,
      where: r.voile_user_id == ^user_id and c.is_valid == true and is_nil(e.deleted_at),
      select: %{
        id: c.id,
        certificate_number: c.certificate_number,
        recipient_name: c.recipient_name,
        event_title: e.title,
        event_date: c.event_date,
        training_hours: e.training_hours,
        issued_at: c.issued_at,
        verification_token: c.verification_token,
        slug: e.slug
      },
      order_by: [desc: c.issued_at]
    )
    |> Repo.all()
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto py-8 px-4 space-y-6">
        <div>
          <h1 class="text-2xl font-bold text-base-content">Sertifikat Saya</h1>
          <p class="text-sm text-base-content/60 mt-1">
            Semua sertifikat yang diterbitkan untuk akun Anda.
          </p>
        </div>

        <%= if @certificates == [] do %>
          <div class="bg-base-100 border border-base-300 rounded-2xl p-10 text-center">
            <.icon name="hero-academic-cap" class="size-12 text-base-content/20 mx-auto mb-3" />
            <p class="text-sm text-base-content/50">
              Belum ada sertifikat. Sertifikat akan muncul setelah Anda mengikuti event dan penyelenggara menerbitkannya.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for cert <- @certificates do %>
              <div class="bg-base-100 border border-base-300 rounded-2xl p-5 flex items-start gap-4">
                <div class="w-12 h-12 rounded-xl bg-success/15 flex items-center justify-center shrink-0">
                  <.icon name="hero-academic-cap" class="size-6 text-success" />
                </div>
                <div class="flex-1 min-w-0">
                  <p class="font-semibold text-sm text-base-content">{cert.event_title}</p>
                  <p class="text-xs text-base-content/50 mt-0.5">
                    {TimeFormat.date(cert.event_date)}
                    <%= if cert.training_hours do %>
                      · {cert.training_hours} jam pelatihan
                    <% end %>
                  </p>
                  <p class="text-xs font-mono text-base-content/40 mt-0.5">
                    {cert.certificate_number}
                  </p>
                </div>
                <.link
                  navigate={~p"/certificates/verify/#{cert.verification_token}"}
                  class="btn btn-xs btn-outline btn-primary shrink-0"
                >
                  Lihat
                </.link>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
