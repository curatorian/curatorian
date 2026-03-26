defmodule CuratorianWeb.Public.Tools.Library.Classification.IndexLive do
  @moduledoc """
  Public browse-and-search for library classification entries.
  """

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @per_page Public.page_size()
  @classification_systems ["DDC", "UDC", "LCC"]
  @default_system nil

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Klasifikasi Perpustakaan")
     |> assign(:search, "")
     |> assign(:page, 1)
     |> assign(:view_mode, "list")
     |> assign(:system, @default_system)
     |> assign(:total_pages, 1)
     |> assign(:total_count, 0)
     |> assign(:page_count, 0)
     |> assign(:domain_counts, %{ddc: 0, udc: 0, lcc: 0})
     |> assign(:has_more, false)
     |> assign(:expanded_systems, Enum.into(@classification_systems, %{}, fn s -> {s, false} end))
     |> assign(:expanded_majors, %{})
     |> assign(:expanded_divisions, %{})
     |> stream(:classifications, [], reset: true)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    search = Map.get(params, "q", "") |> String.trim()
    page = max(1, safe_to_integer(Map.get(params, "page", "1")))
    view_mode = Map.get(params, "view", "list")
    system = normalize_system(Map.get(params, "system", ""))

    classifications =
      if view_mode == "tree" do
        []
      else
        Public.list_classifications(search, page: page, system: system)
      end

    tree_classifications = Public.list_classifications_for_tree(search, system)

    total_count = Public.count_classifications(search, system: system)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page_count = length(classifications)
    has_more = view_mode == "list" and page < total_pages

    domain_counts = %{
      ddc: Public.count_classifications(search, system: "DDC"),
      udc: Public.count_classifications(search, system: "UDC"),
      lcc: Public.count_classifications(search, system: "LCC")
    }

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:page, page)
     |> assign(:view_mode, view_mode)
     |> assign(:system, system)
     |> assign(:total_pages, total_pages)
     |> assign(:total_count, total_count)
     |> assign(:page_count, page_count)
     |> assign(:domain_counts, domain_counts)
     |> assign(:has_more, has_more)
     |> assign(:tree, build_tree(tree_classifications))
     |> assign(
       :expanded_systems,
       socket.assigns.expanded_systems ||
         Enum.into(@classification_systems, %{}, fn s -> {s, false} end)
     )
     |> assign(:expanded_majors, socket.assigns.expanded_majors || %{})
     |> assign(:expanded_divisions, socket.assigns.expanded_divisions || %{})
     |> stream(:classifications, classifications, reset: true)}
  end

  @impl true
  def handle_event("search", params, socket) when is_map(params) do
    q =
      cond do
        is_binary(params["q"]) ->
          params["q"]

        is_binary(params["value"]) ->
          params["value"]

        is_map(params["value"]) and is_binary(params["value"]["value"]) ->
          params["value"]["value"]

        true ->
          nil
      end

    if is_binary(q) do
      query = String.trim(q)
      path = build_path(1, query, socket.assigns.system, socket.assigns.view_mode)
      {:noreply, push_patch(socket, to: path)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_view", %{"mode" => mode}, socket) do
    mode = if(mode in ["list", "tree"], do: mode, else: "list")
    path = build_path(1, socket.assigns.search, socket.assigns.system, mode)
    {:noreply, push_patch(socket, to: path)}
  end

  @impl true
  def handle_event("toggle_major", %{"system" => system, "major" => major}, socket) do
    key = "#{system}_#{major}"

    expanded_majors =
      Map.update(socket.assigns.expanded_majors || %{}, key, true, fn v -> not v end)

    {:noreply, assign(socket, :expanded_majors, expanded_majors)}
  end

  @impl true
  def handle_event(
        "toggle_division",
        %{"system" => system, "major" => major, "division" => division},
        socket
      ) do
    key = "#{system}_#{major}_#{division}"
    expanded = Map.update(socket.assigns.expanded_divisions || %{}, key, true, fn v -> not v end)
    {:noreply, assign(socket, :expanded_divisions, expanded)}
  end

  @impl true
  def handle_event("set_system", %{"system" => system}, socket) do
    system = normalize_system(system)
    path = build_path(1, socket.assigns.search, system, socket.assigns.view_mode)
    {:noreply, push_patch(socket, to: path)}
  end

  @impl true
  def handle_event("toggle_system", %{"system" => system}, socket) do
    expanded_systems =
      Map.update(socket.assigns.expanded_systems || %{}, system, true, fn v -> not v end)

    {:noreply, assign(socket, :expanded_systems, expanded_systems)}
  end

  @impl true
  def handle_event("prev_page", _, socket) do
    page = max(1, socket.assigns.page - 1)

    path =
      build_path(page, socket.assigns.search, socket.assigns.system, socket.assigns.view_mode)

    {:noreply, push_patch(socket, to: path)}
  end

  @impl true
  def handle_event("next_page", _, socket) do
    page = min(socket.assigns.total_pages, socket.assigns.page + 1)

    path =
      build_path(page, socket.assigns.search, socket.assigns.system, socket.assigns.view_mode)

    {:noreply, push_patch(socket, to: path)}
  end

  defp build_path(page, search, system, view_mode) do
    params = %{"page" => to_string(page), "view" => view_mode}
    params = if(search == "", do: params, else: Map.put(params, "q", search))

    params =
      if(system in @classification_systems, do: Map.put(params, "system", system), else: params)

    "/tools/library/classifications?" <> URI.encode_query(params)
  end

  defp normalize_system(system) when system in @classification_systems, do: system
  defp normalize_system(""), do: @default_system
  defp normalize_system(nil), do: @default_system
  defp normalize_system(_), do: @default_system

  defp safe_to_integer(value) when is_integer(value), do: value

  defp safe_to_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {n, ""} when n >= 1 -> n
      {n, _} when n >= 1 -> n
      _ -> 1
    end
  end

  defp safe_to_integer(_), do: 1

  defp build_tree(classifications) do
    classifications
    |> Enum.group_by(& &1.system)
    |> Enum.sort_by(fn {system, _} -> system end)
    |> Enum.map(fn {system, entries} ->
      {system, build_tree_for_system(entries)}
    end)
  end

  defp build_tree_for_system(entries) do
    entries
    |> Enum.group_by(&to_major_class/1)
    |> Enum.sort_by(fn {major, _} -> major end)
    |> Enum.map(fn {major, major_entries} ->
      major_subject = get_major_subject(major_entries, major)

      divisions =
        major_entries
        |> Enum.group_by(&to_division_class/1)
        |> Enum.sort_by(fn {division, _} -> division end)
        |> Enum.map(fn {division, division_entries} ->
          division_subject = get_division_subject(division_entries, division)

          {
            division,
            division_subject,
            division_entries
            |> Enum.sort_by(& &1.code)
            |> Enum.map(fn item ->
              %{item | code: item.code, subject: item.subject}
            end)
          }
        end)

      {major, major_subject, divisions}
    end)
  end

  defp get_major_subject(entries, major) do
    entries
    |> Enum.find(fn entry -> entry.code == major end)
    |> case do
      nil -> entries |> List.first() |> Map.get(:subject, "")
      entry -> entry.subject
    end
  end

  defp get_division_subject(entries, division) do
    entries
    |> Enum.find(fn entry -> entry.code == division end)
    |> case do
      nil -> entries |> List.first() |> Map.get(:subject, "")
      entry -> entry.subject
    end
  end

  defp to_major_class(%{code: code}), do: to_major_class(code)

  defp to_major_class(code) when is_binary(code) and byte_size(code) >= 1 do
    String.slice(code <> "000", 0, 1) <> "00"
  end

  defp to_major_class(_), do: "000"

  defp to_division_class(%{code: code}), do: to_division_class(code)

  defp to_division_class(code) when is_binary(code) and byte_size(code) >= 2 do
    String.slice(code <> "000", 0, 2) <> "0"
  end

  defp to_division_class(_), do: "000"

  defp system_info("DDC") do
    "Dewey Decimal Classification - Sistem paling luas digunakan di dunia, terutama oleh perpustakaan umum dan perpustakaan sekolah. Menggunakan angka desimal yang intuitif dan mudah dipelajari. Digunakan di 135+ negara."
  end

  defp system_info("UDC") do
    "Universal Decimal Classification - Dikembangkan dari DDC namun jauh lebih rinci dan fleksibel. Populer di Eropa dan perpustakaan khusus yang membutuhkan kedalaman subjek tinggi. Menggunakan tanda baca seperti +, /, dan : untuk menyatakan hubungan antar topik."
  end

  defp system_info("LCC") do
    "Library of Congress Classification - Digunakan oleh Perpustakaan Kongres AS dan banyak perpustakaan akademik besar. Menggunakan kombinasi huruf dan angka, dirancang untuk koleksi yang sangat besar dan beragam. Standar di perpustakaan akademik AS."
  end

  defp system_info(_), do: ""

  defp system_reference_link("DDC"), do: "https://www.oclc.org/en/dewey.html"
  defp system_reference_link("UDC"), do: "https://udcc.org/index.php"
  defp system_reference_link("LCC"), do: "https://www.loc.gov/aba/cataloging/classification/"
  defp system_reference_link(_), do: "#"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto p-4 sm:p-6">
        <div class="mb-6 rounded-2xl border border-base-300/70 bg-gradient-to-r from-indigo-50 via-white to-sky-50 dark:from-slate-800 dark:via-slate-900 dark:to-slate-700 p-6 shadow-lg">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <h3 class="text-3xl sm:text-4xl font-bold text-slate-900 dark:text-slate-100">
                Klasifikasi Perpustakaan
              </h3>
              <p class="mt-2 text-sm sm:text-base text-slate-700 dark:text-slate-300 max-w-2xl">
                Temukan kode dan subjek perpustakaan dalam DDC, UDC, dan LCC dengan cepat dan presisi. Ini membantu pustakawan, peneliti, dan pelajar memilih klasifikasi yang tepat untuk koleksi mereka.
              </p>
              <p>
                Lihat apa itu klasifikasi perpustakaan :
                <a
                  href="/library/classification"
                  class="text-blue-500 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300"
                >
                  Baca selengkapnya &rightarrow;
                </a>
              </p>
            </div>
            <div class="rounded-xl border border-base-300 bg-white dark:bg-slate-800 px-4 py-2 text-xs dark:text-slate-200 shadow-sm">
              <p class="font-semibold text-slate-800 dark:text-slate-100">Fitur Utama</p>
              <ul class="list-disc pl-5 mt-2 space-y-1">
                <li>Pencarian teks lengkap menurut kode/subjek</li>
                <li>Filter sistem: DDC, UDC, LCC</li>
                <li>Mode daftar & pohon hierarki</li>
                <li>Salin kode dengan sekali klik</li>
              </ul>
            </div>
          </div>
        </div>

        <.link
          navigate="/library/classification"
          class="btn btn-primary mb-4"
        >
          &leftarrow; Kembali ke halaman klasifikasi
        </.link>

        <div class="mb-4 grid grid-cols-1 md:grid-cols-3 gap-3">
          <div class="md:col-span-2">
            <input
              type="text"
              name="q"
              value={@search}
              placeholder="Cari kode, subjek, atau sistem..."
              class="w-full border border-base-300 rounded-xl px-4 py-2 text-sm focus:border-primary focus:ring focus:ring-primary/30 outline-none"
              phx-debounce="300"
              phx-keyup="search"
            />
          </div>

          <div class="flex items-center gap-2">
            <p class="text-sm text-base-content/60">
              Hasil: {@total_count} · Halaman {@page} dari {@total_pages}
              <%= if @system do %>
                · Sistem: {@system}
              <% end %>
            </p>
          </div>
        </div>

        <div class="mb-4 flex flex-wrap items-center gap-2">
          <button
            type="button"
            phx-click="toggle_view"
            phx-value-mode="list"
            class={
              "btn btn-sm " <>
                if(@view_mode == "list", do: "btn-primary", else: "btn-outline")
            }
          >
            List
          </button>
          <button
            type="button"
            phx-click="toggle_view"
            phx-value-mode="tree"
            class={
              "btn btn-sm " <>
                if(@view_mode == "tree", do: "btn-primary", else: "btn-outline")
            }
          >
            Tree
          </button>

          <div class="ml-auto flex gap-2">
            <button
              type="button"
              phx-click="set_system"
              phx-value-system="DDC"
              class={
                "btn btn-xs " <>
                  if(@system == "DDC", do: "btn-secondary", else: "btn-outline")
              }
            >
              DDC ({@domain_counts.ddc})
            </button>
            <button
              type="button"
              phx-click="set_system"
              phx-value-system="UDC"
              class={
                "btn btn-xs " <>
                  if(@system == "UDC", do: "btn-secondary", else: "btn-outline")
              }
            >
              UDC ({@domain_counts.udc})
            </button>
            <button
              type="button"
              phx-click="set_system"
              phx-value-system="LCC"
              class={
                "btn btn-xs " <>
                  if(@system == "LCC", do: "btn-secondary", else: "btn-outline")
              }
            >
              LCC ({@domain_counts.lcc})
            </button>
            <button
              type="button"
              phx-click="set_system"
              phx-value-system=""
              class={
                "btn btn-xs " <>
                  if(is_nil(@system), do: "btn-primary", else: "btn-outline")
              }
            >
              Semua ({@total_count})
            </button>
          </div>
        </div>

        <div class="rounded-[var(--radius-box)] border border-base-300/60 bg-base-100 overflow-hidden">
          <%= if @view_mode == "list" do %>
            <div id="classifications" phx-update="stream" class="divide-y divide-base-300/40">
              <div
                :for={{id, classification} <- @streams.classifications}
                id={id}
                class="px-4 sm:px-6 py-4"
              >
                <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-2">
                  <div class="min-w-0">
                    <p class="font-semibold text-base-content truncate">
                      {classification.system} • {classification.code} — {classification.subject}
                    </p>
                    <p class="text-xs text-base-content/70">Status: {classification.status}</p>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="text-xs text-base-content/60">
                      ID: {classification.id}
                    </span>
                    <button
                      type="button"
                      id={"copy-" <> to_string(classification.id)}
                      phx-hook="CopyCode"
                      data-code={classification.code}
                      class="btn btn-ghost btn-xs"
                    >
                      Copy
                    </button>
                  </div>
                </div>
              </div>
            </div>
          <% else %>
            <div class="px-6 py-4">
              <div class="space-y-4">
                <%= for {system, majors} <- @tree do %>
                  <div class="border border-base-200 rounded-lg p-3 bg-base-100">
                    <div class="mb-3 flex items-center justify-between gap-2">
                      <div>
                        <h2 class="text-sm font-semibold text-base-content">{system}</h2>
                        <div class="text-xs text-base-content/70 mt-1 space-y-1">
                          <p>{system_info(system)}</p>
                          <p>
                            <a
                              href={system_reference_link(system)}
                              target="_blank"
                              rel="noopener noreferrer"
                              class="text-xs text-primary hover:underline"
                            >
                              Sumber resmi
                            </a>
                          </p>
                        </div>
                      </div>
                      <div class="flex items-center gap-2">
                        <span class="text-xs text-base-content/60">
                          {length(majors)} major group(s)
                        </span>
                        <button
                          type="button"
                          phx-click="toggle_system"
                          phx-value-system={system}
                          class="btn btn-ghost btn-xs"
                        >
                          {if @expanded_systems[system], do: "▾ Collapse", else: "▸ Expand"}
                        </button>
                      </div>
                    </div>

                    <%= if @expanded_systems[system] do %>
                      <div class="space-y-4">
                        <%= for {major, major_subject, divisions} <- majors do %>
                          <div class="border border-base-200 rounded-lg p-3 mb-3">
                            <div class="flex items-center justify-between">
                              <h5 class="text-base font-semibold text-base-content">
                                {major} — {major_subject}
                              </h5>
                              <button
                                type="button"
                                phx-click="toggle_major"
                                phx-stop-propagation
                                phx-value-system={system}
                                phx-value-major={major}
                                class="btn btn-ghost btn-xs"
                              >
                                {if @expanded_majors["#{system}_#{major}"], do: "▾", else: "▸"}
                              </button>
                            </div>

                            <%= if @expanded_majors["#{system}_#{major}"] do %>
                              <div class="mt-3 space-y-2">
                                <%= for {division, division_subject, entries} <- divisions do %>
                                  <div class="border border-base-200 rounded-lg p-2">
                                    <div class="flex items-center justify-between">
                                      <div class="text-sm font-medium text-base-content">
                                        {division} — {division_subject}
                                      </div>
                                      <button
                                        type="button"
                                        phx-click="toggle_division"
                                        phx-stop-propagation
                                        phx-value-system={system}
                                        phx-value-major={major}
                                        phx-value-division={division}
                                        class="btn btn-ghost btn-xs"
                                      >
                                        {if @expanded_divisions["#{system}_#{major}_#{division}"],
                                          do: "▾",
                                          else: "▸"}
                                      </button>
                                    </div>

                                    <%= if @expanded_divisions["#{system}_#{major}_#{division}"] do %>
                                      <ul class="pl-4 mt-2 space-y-1">
                                        <%= for item <- entries do %>
                                          <li class="flex items-center justify-between text-sm text-base-content/80">
                                            <span>
                                              <span class="font-medium">{item.code}</span>
                                              — {item.subject}
                                            </span>
                                            <button
                                              type="button"
                                              id={"copy-" <> to_string(item.id)}
                                              phx-hook="CopyCode"
                                              data-code={item.code}
                                              class="btn btn-ghost btn-xs"
                                            >
                                              Copy
                                            </button>
                                          </li>
                                        <% end %>
                                      </ul>
                                    <% end %>
                                  </div>
                                <% end %>
                              </div>
                            <% end %>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <div :if={@total_count == 0} class="px-6 py-10 text-center text-base-content/70">
            Hasil tidak ditemukan untuk pencarian ini. Coba kata kunci lain.
          </div>

          <div class="px-6 py-4 border-t border-base-300/60 flex flex-wrap items-center justify-between gap-2">
            <div class="text-sm text-base-content/70">
              Menampilkan {@page_count} item dari {@total_count}
            </div>

            <%= if @view_mode == "list" do %>
              <div class="flex gap-2">
                <button
                  type="button"
                  phx-click="prev_page"
                  class="btn btn-sm btn-outline"
                  disabled={@page <= 1}
                >
                  Sebelumnya
                </button>
                <button
                  type="button"
                  phx-click="next_page"
                  class="btn btn-sm btn-outline"
                  disabled={@page >= @total_pages}
                >
                  Berikutnya
                </button>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <div
        id="copy-toast"
        class="fixed bottom-4 right-4 bg-base-100 text-base-content dark:bg-slate-800 dark:text-slate-100 px-4 py-2 rounded-lg shadow-lg border border-base-300 dark:border-slate-600 transition-all duration-300 opacity-0 translate-y-4 pointer-events-none z-50"
      >
      </div>
    </Layouts.app>
    """
  end
end
