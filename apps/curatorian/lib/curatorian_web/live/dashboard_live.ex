defmodule CuratorianWeb.DashboardLive do
  @moduledoc """
  Entry point for logged-in users at `/dashboard`.

  Curatorian has two distinct workspaces and users regularly confuse them, so
  this page explains each one and routes people to the right place:

    * **Foyer** — the personal space (registered events, certificates, job
      applications, collections from followed organizations).
    * **Atrium** — the management app for organizers/institutions (catalog,
      collections, events, participants, certificates, org site).
  """

  use CuratorianWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:display_name, display_name(user))
     |> assign(:atrium_url, atrium_url())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="relative min-h-screen">
        <div class="pointer-events-none absolute inset-x-0 top-0 h-[24rem] bg-gradient-to-b from-primary/10 via-secondary/5 to-transparent" />

        <div class="relative mx-auto w-full max-w-5xl px-4 py-10 sm:px-6 lg:px-8">
          <header class="space-y-2">
            <p class="text-[11px] font-semibold uppercase tracking-[0.2em] text-base-content/50">
              Dashboard
            </p>
            <h1 class="text-balance text-3xl font-bold tracking-tight text-base-content sm:text-4xl">
              Halo, {@display_name} 👋
            </h1>
            <p class="max-w-2xl text-sm leading-relaxed text-base-content/70">
              Curatorian punya dua ruang kerja. Pilih tempat yang sesuai dengan
              yang ingin Anda lakukan hari ini.
            </p>
          </header>

          <div class="mt-8 grid grid-cols-1 gap-6 md:grid-cols-2">
            <%!-- Foyer --%>
            <section class="group flex flex-col overflow-hidden rounded-3xl border border-base-300/60 bg-base-100 shadow-[0_20px_50px_-32px_rgba(15,23,42,0.4)] transition hover:-translate-y-0.5 hover:border-primary/40 hover:shadow-[0_28px_60px_-32px_rgba(15,23,42,0.45)]">
              <div class="bg-gradient-to-br from-violet-500/15 via-indigo-500/10 to-transparent px-6 pb-5 pt-6">
                <span class="flex size-12 items-center justify-center rounded-2xl bg-violet-500/15 text-violet-600 dark:text-violet-400">
                  <.icon name="hero-home-modern" class="size-6" />
                </span>
                <h2 class="mt-4 text-xl font-bold tracking-tight text-base-content">Foyer</h2>
                <p class="mt-1 text-sm text-base-content/70">
                  Ruang pribadi Anda sebagai peserta dan anggota komunitas.
                </p>
              </div>

              <div class="flex flex-1 flex-col gap-4 px-6 pb-6 mt-8">
                <ul class="space-y-2 text-sm text-base-content/75">
                  <li class="flex items-start gap-2">
                    <.icon name="hero-check-circle" class="mt-0.5 size-4 shrink-0 text-violet-500" />
                    Event yang Anda ikuti, kode check-in, dan sertifikat
                  </li>
                  <li class="flex items-start gap-2">
                    <.icon name="hero-check-circle" class="mt-0.5 size-4 shrink-0 text-violet-500" />
                    Status lamaran kerja dan riwayat pembayaran
                  </li>
                  <li class="flex items-start gap-2">
                    <.icon name="hero-check-circle" class="mt-0.5 size-4 shrink-0 text-violet-500" />
                    Koleksi terbaru dari organisasi yang Anda ikuti
                  </li>
                </ul>

                <.link
                  navigate="/foyer"
                  class="mt-auto inline-flex w-full items-center justify-center gap-2 rounded-xl bg-violet-600 px-4 py-3 text-sm font-semibold text-white shadow-lg shadow-violet-500/20 transition hover:brightness-105"
                >
                  Buka Foyer <.icon name="hero-arrow-right" class="size-4" />
                </.link>
              </div>
            </section>

            <%!-- Atrium --%>
            <section class="group flex flex-col overflow-hidden rounded-3xl border border-base-300/60 bg-base-100 shadow-[0_20px_50px_-32px_rgba(15,23,42,0.4)] transition hover:-translate-y-0.5 hover:border-primary/40 hover:shadow-[0_28px_60px_-32px_rgba(15,23,42,0.45)]">
              <div class="bg-gradient-to-br from-primary/15 via-secondary/10 to-transparent px-6 pb-5 pt-6">
                <span class="flex size-12 items-center justify-center rounded-2xl bg-primary/15 text-primary">
                  <.icon name="hero-building-library" class="size-6" />
                </span>
                <h2 class="mt-4 text-xl font-bold tracking-tight text-base-content">Atrium</h2>
                <p class="mt-1 text-sm text-base-content/70">
                  Panel pengelolaan untuk organisasi, kurator, dan pengelola acara.
                </p>
              </div>

              <div class="flex flex-1 flex-col gap-4 px-6 pb-6 mt-4">
                <ul class="space-y-2 text-sm text-base-content/75">
                  <li class="flex items-start gap-2">
                    <.icon name="hero-check-circle" class="mt-0.5 size-4 shrink-0 text-primary" />
                    Mengelola katalog dan koleksi milik Anda dalam satu dashboard.
                  </li>
                  <li class="flex items-start gap-2">
                    <.icon name="hero-check-circle" class="mt-0.5 size-4 shrink-0 text-primary" />
                    Kelola event: peserta, kehadiran, pembayaran, sertifikat
                  </li>
                  <li class="flex items-start gap-2">
                    <.icon name="hero-check-circle" class="mt-0.5 size-4 shrink-0 text-primary" />
                    Profil organisasi, tim pengelola, dan langganan
                  </li>
                </ul>

                <a
                  href={@atrium_url}
                  class="mt-auto inline-flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-primary to-secondary px-4 py-3 text-sm font-semibold text-primary-content shadow-lg shadow-primary/25 transition hover:brightness-105"
                >
                  Buka Atrium <.icon name="hero-arrow-top-right-on-square" class="size-4" />
                </a>

                <p class="text-center text-[11px] text-base-content/45">
                  Butuh akses pengelola? Hubungi admin organisasi Anda.
                </p>
              </div>
            </section>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp display_name(user) do
    cond do
      is_binary(user.fullname) and user.fullname != "" -> user.fullname
      is_binary(user.username) and user.username != "" -> user.username
      true -> "Kurator"
    end
  end

  defp atrium_url do
    base = Application.get_env(:curatorian, :atrium_url, "http://localhost:4001")
    String.trim_trailing(base, "/") <> "/dashboard"
  end
end
