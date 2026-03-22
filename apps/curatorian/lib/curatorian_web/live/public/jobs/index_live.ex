defmodule CuratorianWeb.Public.Jobs.IndexLive do
  @moduledoc "Public job board listing (/jobs)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @employment_options [
    {"Semua", nil},
    {"Penuh Waktu", "full_time"},
    {"Paruh Waktu", "part_time"},
    {"Magang", "magang"},
    {"Sukarelawan", "volunteer"},
    {"Kontrak", "contract"},
    {"Freelance", "freelance"}
  ]

  @category_options [
    {"Semua", nil},
    {"Perpustakaan", "library"},
    {"Arsip", "archives"},
    {"Museum", "museum"},
    {"Galeri", "gallery"},
    {"Pendidikan", "education"},
    {"Penelitian", "research"},
    {"Teknologi", "technology"},
    {"Lainnya", "other"}
  ]

  @location_options [
    {"Semua", nil},
    {"Di Kantor", "onsite"},
    {"Remote", "remote"},
    {"Hybrid", "hybrid"}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Lowongan Kerja GLAM Indonesia")
     |> assign(:search, "")
     |> assign(:employment_type, nil)
     |> assign(:category, nil)
     |> assign(:location_type, nil)
     |> assign(:page, 1)
     |> assign(:job_postings_count, 0)
     |> assign(:employment_options, @employment_options)
     |> assign(:category_options, @category_options)
     |> assign(:location_options, @location_options)}
  end

  def handle_params(params, _uri, socket) do
    q = Map.get(params, "q", "")
    employment_type = Map.get(params, "employment_type", nil)
    category = Map.get(params, "category", nil)
    location_type = Map.get(params, "location_type", nil)
    page = String.to_integer(Map.get(params, "page", "1"))

    job_postings =
      Public.list_active_job_postings(
        search: q,
        employment_type: employment_type,
        category: category,
        location_type: location_type,
        page: page
      )

    {:noreply,
     socket
     |> assign(:search, q)
     |> assign(:employment_type, employment_type)
     |> assign(:category, category)
     |> assign(:location_type, location_type)
     |> assign(:page, page)
     |> assign(:job_postings_count, length(job_postings))
     |> assign(:has_more, length(job_postings) == Public.page_size())
     |> stream(:job_postings, job_postings, reset: true)}
  end

  def handle_event("search", %{"q" => q}, socket) do
    params =
      build_params(
        q,
        socket.assigns.employment_type,
        socket.assigns.category,
        socket.assigns.location_type,
        1
      )

    {:noreply, push_patch(socket, to: ~p"/jobs?#{params}")}
  end

  def handle_event(
        "filter",
        %{
          "employment_type" => employment_type,
          "category" => category,
          "location_type" => location_type
        },
        socket
      ) do
    employment_type = if employment_type == "", do: nil, else: employment_type
    category = if category == "", do: nil, else: category
    location_type = if location_type == "", do: nil, else: location_type

    params = build_params(socket.assigns.search, employment_type, category, location_type, 1)
    {:noreply, push_patch(socket, to: ~p"/jobs?#{params}")}
  end

  def handle_event("load_more", _, socket) do
    next_page = socket.assigns.page + 1

    job_postings =
      Public.list_active_job_postings(
        search: socket.assigns.search,
        employment_type: socket.assigns.employment_type,
        category: socket.assigns.category,
        location_type: socket.assigns.location_type,
        page: next_page
      )

    updated_count = socket.assigns.job_postings_count + length(job_postings)

    {:noreply,
     socket
     |> assign(:page, next_page)
     |> assign(:job_postings_count, updated_count)
     |> assign(:has_more, length(job_postings) == Public.page_size())
     |> stream(:job_postings, job_postings)}
  end

  defp build_params(search, employment_type, category, location_type, page) do
    %{}
    |> then(fn map -> if(search != "", do: Map.put(map, "q", search), else: map) end)
    |> then(fn map ->
      if(employment_type, do: Map.put(map, "employment_type", employment_type), else: map)
    end)
    |> then(fn map -> if(category, do: Map.put(map, "category", category), else: map) end)
    |> then(fn map ->
      if(location_type, do: Map.put(map, "location_type", location_type), else: map)
    end)
    |> then(fn map -> if(page > 1, do: Map.put(map, "page", to_string(page)), else: map) end)
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto py-8 px-4">
        <div class="mb-8">
          <h1 class="text-3xl sm:text-4xl font-semibold text-base-content mb-2">
            Lowongan Kerja GLAM Indonesia
          </h1>
          <p class="text-base text-base-content/60">
            Temukan peluang karier di sektor perpustakaan, arsip, museum, dan galeri
          </p>
        </div>

        <form phx-change="filter" class="grid grid-cols-1 md:grid-cols-4 gap-3 mb-6">
          <div class="md:col-span-2">
            <input
              type="text"
              name="q"
              value={@search}
              placeholder="Cari judul, institusi, atau kota..."
              class="w-full border border-base-300 rounded-xl px-4 py-2 text-sm focus:border-primary focus:outline-none"
              phx-debounce="300"
              phx-keyup="search"
            />
          </div>

          <div>
            <select
              name="employment_type"
              class="w-full border border-base-300 rounded-xl px-3 py-2 text-sm"
            >
              <%= for {label, val} <- @employment_options do %>
                <option value={val || ""} selected={@employment_type == val}>{label}</option>
              <% end %>
            </select>
          </div>

          <div>
            <select name="category" class="w-full border border-base-300 rounded-xl px-3 py-2 text-sm">
              <%= for {label, val} <- @category_options do %>
                <option value={val || ""} selected={@category == val}>{label}</option>
              <% end %>
            </select>
          </div>

          <div>
            <select
              name="location_type"
              class="w-full border border-base-300 rounded-xl px-3 py-2 text-sm"
            >
              <%= for {label, val} <- @location_options do %>
                <option value={val || ""} selected={@location_type == val}>{label}</option>
              <% end %>
            </select>
          </div>
        </form>

        <div id="jobs" phx-update="stream" class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div :for={{id, job} <- @streams.job_postings} id={id}>
            <.job_card posting={job} />
          </div>
        </div>

        <div
          :if={@job_postings_count == 0}
          class="p-10 border border-base-300 rounded-2xl text-center text-base-content/70"
        >
          Belum ada lowongan aktif saat ini. Cek kembali nanti!
        </div>

        <div :if={@has_more} class="flex justify-center mt-8">
          <button
            phx-click="load_more"
            class="px-6 py-2 rounded-full border border-primary text-primary hover:bg-primary hover:text-primary-content transition"
          >
            Muat lebih banyak
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp job_card(assigns) do
    ~H"""
    <article class="bg-base-100 rounded-2xl border border-base-300 shadow-sm hover:shadow-md transition overflow-hidden">
      <div class="p-3">
        <.icon
          name={if assigns.posting.is_featured, do: "hero-star", else: "hero-briefcase"}
          class="size-4 text-secondary"
        />
      </div>
      <div class="p-4">
        <div class="flex items-center gap-2 mb-2">
          <span class="badge badge-sm bg-base-200 text-base-content">
            {to_label(assigns.posting.employment_type)}
          </span>
          <span class="badge badge-sm bg-base-200 text-base-content">
            {to_label(assigns.posting.category)}
          </span>
          <span
            :if={assigns.posting.is_featured}
            class="badge badge-sm bg-yellow-100 text-yellow-800 font-semibold"
          >
            Unggulan
          </span>
        </div>

        <h2 class="text-lg font-semibold text-base-content leading-snug">{assigns.posting.title}</h2>
        <p class="text-sm text-base-content/70">{assigns.posting.institution_name}</p>

        <div class="mt-3 text-xs text-base-content/60 space-y-1">
          <p>📍 {location_text(assigns.posting)}</p>
          <p>🕐 Batas lamaran: {deadline_text(assigns.posting)}</p>
          <p>👥 {assigns.posting.application_count || 0} pelamar</p>
        </div>

        <.link
          navigate={~p"/jobs/#{assigns.posting.slug}"}
          class="inline-flex items-center justify-end mt-4 w-full text-sm font-semibold text-primary"
        >
          Lihat &rarr;
        </.link>
      </div>
    </article>
    """
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

  defp deadline_text(posting) do
    if posting.application_deadline do
      posting.application_deadline
      |> DateTime.to_date()
      |> Date.to_string()
    else
      "Tidak ditentukan"
    end
  end

  defp to_label(nil), do: "-"
  defp to_label("full_time"), do: "Penuh Waktu"
  defp to_label("part_time"), do: "Paruh Waktu"
  defp to_label("magang"), do: "Magang"
  defp to_label("volunteer"), do: "Sukarelawan"
  defp to_label("contract"), do: "Kontrak"
  defp to_label("freelance"), do: "Freelance"
  defp to_label("library"), do: "Perpustakaan"
  defp to_label("archives"), do: "Arsip"
  defp to_label("museum"), do: "Museum"
  defp to_label("gallery"), do: "Galeri"
  defp to_label("education"), do: "Pendidikan"
  defp to_label("research"), do: "Penelitian"
  defp to_label("technology"), do: "Teknologi"
  defp to_label("other"), do: "Lainnya"
  defp to_label(val), do: to_string(val)
end
