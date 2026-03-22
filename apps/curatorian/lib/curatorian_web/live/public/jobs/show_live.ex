defmodule CuratorianWeb.Public.Jobs.ShowLive do
  @moduledoc "Public job detail page (/jobs/:slug)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  def mount(%{"slug" => slug}, _session, socket) do
    dbg(Public.get_job_posting_by_slug(slug))

    case Public.get_job_posting_by_slug(slug) do
      nil ->
        {:ok,
         socket |> put_flash(:error, "Lowongan tidak ditemukan.") |> push_navigate(to: "/jobs")}

      posting ->
        if posting.status != :active or posting.deleted_at do
          {:ok,
           socket |> put_flash(:error, "Lowongan tidak tersedia.") |> push_navigate(to: "/jobs")}
        else
          user_id = socket.assigns.current_scope && socket.assigns.current_scope.user.id
          has_applied = user_id && Public.get_application_by_user_and_posting(user_id, posting.id)

          {:ok,
           socket
           |> assign(:page_title, "#{posting.title} — #{posting.institution_name}")
           |> assign(:posting, posting)
           |> assign(:has_applied, !!has_applied)
           |> assign(:user_id, user_id)}
        end
    end
  end

  def handle_event("apply", _params, socket) do
    if socket.assigns.posting.application_method == :external_link do
      {:noreply, socket}
    else
      user_id = socket.assigns.user_id

      if is_nil(user_id) do
        {:noreply,
         socket
         |> put_flash(:info, "Masuk untuk melamar")
         |> push_navigate(to: "/login?return_to=/jobs/#{socket.assigns.posting.slug}")}
      else
        {:noreply,
         socket
         |> push_navigate(to: ~p"/jobs/#{socket.assigns.posting.slug}/apply")}
      end
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-5xl mx-auto py-8 px-4 space-y-6">
        <.link navigate="/jobs" class="text-sm text-base-content/60 hover:text-base-content">
          <.icon name="hero-arrow-left" class="size-4" /> Kembali ke daftar lowongan
        </.link>

        <header class="bg-base-100 border border-base-300 rounded-2xl p-6">
          <div class="flex flex-wrap items-start justify-between gap-3">
            <div>
              <p class="text-xs uppercase tracking-widest text-base-content/60 mb-2">
                {posting_badge(assigns.posting)}
              </p>
              <h1 class="text-2xl font-semibold text-base-content">{assigns.posting.title}</h1>
              <p class="text-sm text-base-content/70">{assigns.posting.institution_name}</p>
            </div>
            <div class="text-right">
              <p class="text-sm text-base-content/60">{posted_date(assigns.posting)}</p>
              <p class="text-sm text-base-content/60">{deadline_label(assigns.posting)}</p>
            </div>
          </div>
        </header>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <section class="lg:col-span-2 space-y-5">
            <article class="bg-base-100 border border-base-300 rounded-2xl p-6">
              <p class="text-sm text-base-content font-semibold mb-2">Deskripsi</p>
              <div class="whitespace-pre-line text-base-content/85 text-sm">
                {assigns.posting.description || "-"}
              </div>
            </article>

            <article class="bg-base-100 border border-base-300 rounded-2xl p-6">
              <p class="text-sm text-base-content font-semibold mb-2">Persyaratan</p>
              <div class="whitespace-pre-line text-base-content/85 text-sm">
                {assigns.posting.requirements || "-"}
              </div>
            </article>
          </section>

          <aside class="space-y-4">
            <div class="bg-base-100 border border-base-300 rounded-2xl p-4 space-y-2 text-sm text-base-content/80">
              <p><strong>Batas lamaran:</strong> {deadline_label(assigns.posting)}</p>
              <p><strong>Lokasi:</strong> {location_text(assigns.posting)}</p>
              <p>
                <strong>Metode:</strong> {application_method_label(assigns.posting.application_method)}
              </p>
              <p><strong>Pelamar:</strong> {assigns.posting.application_count || 0}</p>
            </div>

            <div class="bg-base-100 border border-base-300 rounded-2xl p-4">
              <%= if assigns.posting.application_method == :external_link do %>
                <a
                  href={assigns.posting.application_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="inline-flex items-center justify-center w-full px-4 py-2 rounded-xl bg-secondary text-secondary-content font-semibold"
                >
                  Lamar di Website Institusi
                </a>
              <% else %>
                <%= if is_nil(assigns.user_id) do %>
                  <.link
                    navigate={"/login?return_to=/jobs/#{assigns.posting.slug}"}
                    class="inline-flex items-center justify-center w-full px-4 py-2 rounded-xl bg-primary text-primary-content font-semibold"
                  >
                    Masuk untuk melamar
                  </.link>
                <% else %>
                  <.button disabled={assigns.has_applied} phx-click="apply" class="w-full">
                    <%= if assigns.has_applied do %>
                      Lamaran Terkirim ✓
                    <% else %>
                      Lamar Sekarang
                    <% end %>
                  </.button>
                <% end %>
              <% end %>
            </div>
          </aside>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp posting_badge(posting) do
    [
      to_label(posting.employment_type),
      to_label(posting.category),
      to_label(posting.location_type)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" • ")
  end

  defp posted_date(posting) do
    posting.posted_at && DateTime.to_date(posting.posted_at) |> Date.to_string()
  end

  defp deadline_label(posting) do
    if posting.application_deadline do
      DateTime.to_date(posting.application_deadline) |> Date.to_string()
    else
      "Tidak ditentukan"
    end
  end

  defp location_text(posting) do
    cond do
      posting.location_type == :remote ->
        "Remote"

      posting.location_city && posting.location_province ->
        "#{posting.location_city}, #{posting.location_province}"

      posting.location_city ->
        posting.location_city

      true ->
        "-"
    end
  end

  defp application_method_label(:in_platform), do: "Dalam platform"
  defp application_method_label(:external_link), do: "Eksternal"

  defp to_label(:full_time), do: "Penuh Waktu"
  defp to_label(:part_time), do: "Paruh Waktu"
  defp to_label(:magang), do: "Magang"
  defp to_label(:volunteer), do: "Sukarelawan"
  defp to_label(:contract), do: "Kontrak"
  defp to_label(:freelance), do: "Freelance"
  defp to_label(:library), do: "Perpustakaan"
  defp to_label(:archives), do: "Arsip"
  defp to_label(:museum), do: "Museum"
  defp to_label(:gallery), do: "Galeri"
  defp to_label(:education), do: "Pendidikan"
  defp to_label(:research), do: "Penelitian"
  defp to_label(:technology), do: "Teknologi"
  defp to_label(:other), do: "Lainnya"
  defp to_label(_), do: ""
end
