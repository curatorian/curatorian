defmodule CuratorianWeb.Public.Crowdfunding.IndexLive do
  @moduledoc "Public crowdfunding campaign listing (/crowdfunding)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @campaign_type_options [
    {"Semua", nil},
    {"Donasi Dana", :money},
    {"Donasi Item Koleksi", :collection_items},
    {"Campuran", :mixed}
  ]

  @category_options [
    {"Semua", nil},
    {"Perpustakaan", :library},
    {"Arsip", :archives},
    {"Museum", :museum},
    {"Galeri", :gallery},
    {"Pendidikan", :education},
    {"Penelitian", :research},
    {"Lainnya", :other}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Donasi & Crowdfunding GLAM Indonesia")
     |> assign(:search, "")
     |> assign(:campaign_type, nil)
     |> assign(:category, nil)
     |> assign(:page, 1)
     |> assign(:campaigns_count, 0)
     |> assign(:has_more, false)
     |> assign(:campaign_type_options, @campaign_type_options)
     |> assign(:category_options, @category_options)}
  end

  def handle_params(params, _uri, socket) do
    q = Map.get(params, "q", "")
    campaign_type = parse_atom(Map.get(params, "campaign_type", nil))
    category = parse_atom(Map.get(params, "category", nil))
    page = String.to_integer(Map.get(params, "page", "1"))

    campaigns =
      Public.list_active_campaigns(
        search: q,
        campaign_type: campaign_type,
        category: category,
        page: page
      )

    {:noreply,
     socket
     |> assign(:search, q)
     |> assign(:campaign_type, campaign_type)
     |> assign(:category, category)
     |> assign(:page, page)
     |> assign(:campaigns_count, length(campaigns))
     |> assign(:has_more, length(campaigns) == Public.page_size())
     |> stream(:campaigns, campaigns, reset: true)}
  end

  def handle_event("search", %{"q" => q}, socket) do
    params = build_params(q, socket.assigns.campaign_type, socket.assigns.category, 1)
    {:noreply, push_patch(socket, to: ~p"/crowdfunding?#{params}")}
  end

  def handle_event("filter", %{"campaign_type" => ct, "category" => cat}, socket) do
    campaign_type = parse_atom(if ct == "", do: nil, else: ct)
    category = parse_atom(if cat == "", do: nil, else: cat)
    params = build_params(socket.assigns.search, campaign_type, category, 1)
    {:noreply, push_patch(socket, to: ~p"/crowdfunding?#{params}")}
  end

  def handle_event("load_more", _, socket) do
    next_page = socket.assigns.page + 1

    campaigns =
      Public.list_active_campaigns(
        search: socket.assigns.search,
        campaign_type: socket.assigns.campaign_type,
        category: socket.assigns.category,
        page: next_page
      )

    updated_count = socket.assigns.campaigns_count + length(campaigns)

    {:noreply,
     socket
     |> assign(:page, next_page)
     |> assign(:campaigns_count, updated_count)
     |> assign(:has_more, length(campaigns) == Public.page_size())
     |> stream(:campaigns, campaigns)}
  end

  defp build_params(search, campaign_type, category, page) do
    %{}
    |> then(fn map -> if search != "", do: Map.put(map, "q", search), else: map end)
    |> then(fn map ->
      if campaign_type, do: Map.put(map, "campaign_type", campaign_type), else: map
    end)
    |> then(fn map -> if category, do: Map.put(map, "category", category), else: map end)
    |> then(fn map -> if page > 1, do: Map.put(map, "page", to_string(page)), else: map end)
  end

  defp parse_atom(nil), do: nil
  defp parse_atom(""), do: nil
  defp parse_atom(val) when is_atom(val), do: val

  defp parse_atom(val) when is_binary(val) do
    String.to_existing_atom(val)
  rescue
    ArgumentError -> nil
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <%!-- Hero Section --%>
      <div class="bg-gradient-to-br from-primary/10 via-base-100 to-secondary/5 border-b border-base-300">
        <div class="max-w-6xl mx-auto px-4 py-14 text-center">
          <div class="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-1.5 rounded-full text-sm font-medium mb-4">
            <.icon name="hero-heart" class="size-4" /> Dukung GLAM Indonesia
          </div>
          <h1 class="text-3xl sm:text-5xl font-bold text-base-content mb-4 leading-tight">
            Bersama Membangun<br />
            <span class="text-primary">Warisan Pengetahuan Indonesia</span>
          </h1>
          <p class="text-lg text-base-content/60 max-w-2xl mx-auto">
            Donasikan dana atau koleksi untuk mendukung perpustakaan, arsip, museum, dan galeri di seluruh Indonesia.
          </p>
        </div>
      </div>

      <div class="max-w-6xl mx-auto py-8 px-4">
        <%!-- Filters --%>
        <form phx-change="filter" class="grid grid-cols-1 md:grid-cols-4 gap-3 mb-8">
          <div class="md:col-span-2">
            <input
              type="text"
              name="q"
              value={@search}
              placeholder="Cari kampanye crowdfunding..."
              class="w-full border border-base-300 rounded-xl px-4 py-2 text-sm focus:border-primary focus:outline-none"
              phx-debounce="300"
              phx-keyup="search"
            />
          </div>

          <div>
            <select
              name="campaign_type"
              class="w-full border border-base-300 rounded-xl px-3 py-2 text-sm"
            >
              <%= for {label, val} <- @campaign_type_options do %>
                <option value={val || ""} selected={@campaign_type == val}>{label}</option>
              <% end %>
            </select>
          </div>

          <div>
            <select
              name="category"
              class="w-full border border-base-300 rounded-xl px-3 py-2 text-sm"
            >
              <%= for {label, val} <- @category_options do %>
                <option value={val || ""} selected={@category == val}>{label}</option>
              <% end %>
            </select>
          </div>
        </form>

        <%!-- Campaign Grid --%>
        <div
          id="campaigns"
          phx-update="stream"
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
        >
          <div :for={{id, campaign} <- @streams.campaigns} id={id}>
            <.campaign_card campaign={campaign} />
          </div>
        </div>

        <div
          :if={@campaigns_count == 0}
          class="py-16 text-center text-base-content/60 border border-base-300 rounded-2xl"
        >
          <.icon name="hero-megaphone" class="size-12 mx-auto mb-3 opacity-40" />
          <p class="text-lg font-medium">Belum ada kampanye aktif saat ini.</p>
          <p class="text-sm mt-1">Coba ubah filter atau cek kembali nanti.</p>
        </div>

        <div :if={@has_more} class="flex justify-center mt-10">
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

  defp campaign_card(assigns) do
    ~H"""
    <article class="bg-base-100 rounded-2xl border border-base-300 shadow-sm hover:shadow-lg transition group overflow-hidden flex flex-col">
      <%!-- Cover Image --%>
      <%= if @campaign.cover_image_url do %>
        <div class="aspect-video overflow-hidden">
          <img
            src={@campaign.cover_image_url}
            alt={@campaign.title}
            class="w-full h-full object-cover group-hover:scale-105 transition duration-300"
          />
        </div>
      <% else %>
        <div class="aspect-video bg-gradient-to-br from-primary/20 to-secondary/10 flex items-center justify-center">
          <.icon name="hero-heart" class="size-12 text-primary/40" />
        </div>
      <% end %>

      <div class="p-5 flex flex-col flex-1">
        <%!-- Badges --%>
        <div class="flex flex-wrap gap-2 mb-3">
          <span class="badge badge-sm bg-base-200 text-base-content">
            {category_label(@campaign.category)}
          </span>
          <span class={[
            "badge badge-sm font-medium",
            @campaign.campaign_type == :money && "bg-green-100 text-green-800",
            @campaign.campaign_type == :collection_items && "bg-blue-100 text-blue-800",
            @campaign.campaign_type == :mixed && "bg-purple-100 text-purple-800"
          ]}>
            {type_label(@campaign.campaign_type)}
          </span>
        </div>

        <%!-- Title --%>
        <h2 class="text-base font-semibold text-base-content leading-snug mb-1">{@campaign.title}</h2>

        <%!-- Description excerpt --%>
        <p class="text-sm text-base-content/60 line-clamp-2 mb-4 flex-1">
          {@campaign.description}
        </p>

        <%!-- Progress --%>
        <%= if @campaign.campaign_type in [:money, :mixed] and @campaign.goal_amount_idr do %>
          <div class="mb-4">
            <div class="flex justify-between text-xs text-base-content/60 mb-1">
              <span>Terkumpul</span>
              <span class="font-semibold text-primary">
                {format_idr(@campaign.raised_amount_idr || 0)} / {format_idr(
                  @campaign.goal_amount_idr
                )}
              </span>
            </div>
            <div class="w-full bg-base-200 rounded-full h-2">
              <div
                class="bg-primary rounded-full h-2 transition-all"
                style={"width: #{min(money_progress(@campaign), 100)}%"}
              >
              </div>
            </div>
            <p class="text-xs text-base-content/50 mt-1">{@campaign.donor_count || 0} donatur</p>
          </div>
        <% end %>

        <%= if @campaign.campaign_type in [:collection_items, :mixed] and @campaign.item_goal_count do %>
          <div class="mb-4">
            <div class="flex justify-between text-xs text-base-content/60 mb-1">
              <span>Item Diterima</span>
              <span class="font-semibold text-secondary">
                {@campaign.item_received_count || 0} / {@campaign.item_goal_count}
              </span>
            </div>
            <div class="w-full bg-base-200 rounded-full h-2">
              <div
                class="bg-secondary rounded-full h-2 transition-all"
                style={"width: #{min(items_progress(@campaign), 100)}%"}
              >
              </div>
            </div>
          </div>
        <% end %>

        <%!-- CTA --%>
        <.link
          navigate={~p"/crowdfunding/#{@campaign.slug}"}
          class="mt-auto inline-flex items-center justify-center gap-2 w-full py-2.5 rounded-xl bg-primary text-primary-content text-sm font-semibold hover:bg-primary/90 transition"
        >
          <.icon name="hero-heart" class="size-4" /> Lihat Kampanye
        </.link>
      </div>
    </article>
    """
  end

  defp money_progress(%{raised_amount_idr: raised, goal_amount_idr: goal})
       when is_integer(raised) and is_integer(goal) and goal > 0 do
    round(raised / goal * 100)
  end

  defp money_progress(_), do: 0

  defp items_progress(%{item_received_count: received, item_goal_count: goal})
       when is_integer(received) and is_integer(goal) and goal > 0 do
    round(received / goal * 100)
  end

  defp items_progress(_), do: 0

  defp format_idr(nil), do: "Rp 0"

  defp format_idr(amount) do
    formatted =
      amount
      |> Integer.to_string()
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.join(".")
      |> String.reverse()

    "Rp #{formatted}"
  end

  defp category_label(:library), do: "Perpustakaan"
  defp category_label(:archives), do: "Arsip"
  defp category_label(:museum), do: "Museum"
  defp category_label(:gallery), do: "Galeri"
  defp category_label(:education), do: "Pendidikan"
  defp category_label(:research), do: "Penelitian"
  defp category_label(:other), do: "Lainnya"
  defp category_label(nil), do: "-"
  defp category_label(val), do: to_string(val)

  defp type_label(:money), do: "Donasi Dana"
  defp type_label(:collection_items), do: "Donasi Koleksi"
  defp type_label(:mixed), do: "Campuran"
  defp type_label(nil), do: "-"
  defp type_label(val), do: to_string(val)
end
