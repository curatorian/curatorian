defmodule CuratorianWeb.Public.Tools.Library.Classification.IndexLive do
  @moduledoc """
  Public browse-and-search for library classification entries.
  """

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @per_page Public.page_size()

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Klasifikasi Perpustakaan")
     |> assign(:search, "")
     |> assign(:page, 1)
     |> assign(:view_mode, "list")
     |> assign(:system, nil)
     |> assign(:total_pages, 1)
     |> assign(:total_count, 0)
     |> assign(:page_count, 0)
     |> assign(:domain_counts, %{ddc: 0, udc: 0})
     |> assign(:has_more, false)
     |> assign(:expanded_majors, %{})
     |> assign(:expanded_divisions, %{})
     |> stream(:classifications, [], reset: true)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    search = Map.get(params, "q", "") |> String.trim()
    page = max(1, safe_to_integer(Map.get(params, "page", "1")))
    view_mode = Map.get(params, "view", "list")
    system = Map.get(params, "system", nil)

    {classifications, tree_classifications, page_count, total_pages, has_more} =
      if view_mode == "tree" do
        tree = Public.list_classifications_for_tree(search, system)
        {[], tree, length(tree), 1, false}
      else
        classifications = Public.list_classifications(search, page: page, system: system)
        total_count = Public.count_classifications(search, system: system)
        total_pages = max(1, div(total_count + @per_page - 1, @per_page))

        {classifications, Public.list_classifications_for_tree(search, system),
         length(classifications), total_pages, page < total_pages}
      end

    total_count = Public.count_classifications(search, system: system)

    domain_counts = %{
      ddc: Public.count_classifications(search, system: "DDC"),
      udc: Public.count_classifications(search, system: "UDC")
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
     |> assign(:expanded_majors, Map.put_new(socket.assigns.expanded_majors || %{}, "000", true))
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
  def handle_event("toggle_major", %{"major" => major}, socket) do
    expanded_majors =
      Map.update(socket.assigns.expanded_majors || %{}, major, true, fn v -> not v end)

    {:noreply, assign(socket, :expanded_majors, expanded_majors)}
  end

  @impl true
  def handle_event("toggle_division", %{"major" => major, "division" => division}, socket) do
    key = "#{major}_#{division}"
    expanded = Map.update(socket.assigns.expanded_divisions || %{}, key, true, fn v -> not v end)
    {:noreply, assign(socket, :expanded_divisions, expanded)}
  end

  @impl true
  def handle_event("set_system", %{"system" => system}, socket) do
    system = if(system in ["DDC", "UDC"], do: system, else: nil)
    path = build_path(1, socket.assigns.search, system, socket.assigns.view_mode)
    {:noreply, push_patch(socket, to: path)}
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
    params = if(system in ["DDC", "UDC"], do: Map.put(params, "system", system), else: params)

    "/tools/library/classifications?" <> URI.encode_query(params)
  end

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
    |> Enum.group_by(&to_major_class/1)
    |> Enum.sort_by(fn {major, _} -> major end)
    |> Enum.map(fn {major, entries} ->
      major_subject = get_major_subject(entries, major)

      divisions =
        entries
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

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto p-4 sm:p-6">
        <div class="mb-6">
          <h1 class="text-3xl sm:text-4xl font-semibold text-base-content">
            Klasifikasi Perpustakaan
          </h1>
          <p class="mt-1 text-base text-base-content/70">
            Cari klasifikasi DDC / UDC untuk mengetahui subjek dan kode yang sesuai.
          </p>
        </div>

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
              phx-value-system=""
              class="btn btn-xs btn-outline"
            >
              Semua
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
                  <div class="text-xs text-base-content/60">
                    <span class="inline-flex items-center gap-1 rounded-full px-2 py-1 bg-base-200">
                      ID: {classification.id}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          <% else %>
            <div class="px-6 py-4">
              <div class="space-y-4">
                <%= for {major, major_subject, divisions} <- @tree do %>
                  <div class="border border-base-200 rounded-lg p-3">
                    <div class="flex items-center justify-between">
                      <h3 class="text-base font-semibold text-base-content">
                        {major} — {major_subject}
                      </h3>
                      <button
                        type="button"
                        phx-click="toggle_major"
                        phx-value-major={major}
                        class="btn btn-ghost btn-xs"
                      >
                        {if @expanded_majors[major], do: "▾", else: "▸"}
                      </button>
                    </div>

                    <div :if={@expanded_majors[major]} class="mt-3 space-y-2">
                      <%= for {division, division_subject, entries} <- divisions do %>
                        <div class="border border-base-200 rounded-lg p-2">
                          <div class="flex items-center justify-between">
                            <div class="text-sm font-medium text-base-content">
                              {division} — {division_subject}
                            </div>
                            <button
                              type="button"
                              phx-click="toggle_division"
                              phx-value-major={major}
                              phx-value-division={division}
                              class="btn btn-ghost btn-xs"
                            >
                              {if @expanded_divisions[major <> "_" <> division], do: "▾", else: "▸"}
                            </button>
                          </div>

                          <ul
                            :if={@expanded_divisions[major <> "_" <> division]}
                            class="pl-4 mt-2 space-y-1"
                          >
                            <%= for item <- entries do %>
                              <li class="text-sm text-base-content/80">
                                <span class="font-medium">{item.code}</span> — {item.subject}
                              </li>
                            <% end %>
                          </ul>
                        </div>
                      <% end %>
                    </div>
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
    </Layouts.app>
    """
  end
end
