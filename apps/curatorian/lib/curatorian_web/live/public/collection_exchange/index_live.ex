defmodule CuratorianWeb.Public.CollectionExchange.IndexLive do
  @moduledoc "Public collection exchange page (/exchange)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @condition_labels %{
    new: "Baru",
    very_good: "Sangat Baik",
    good: "Baik",
    fair: "Cukup",
    poor: "Kurang Baik"
  }

  @specificity_labels %{
    specific_title: "Judul Spesifik",
    subject_area: "Bidang Subjek",
    format_type: "Jenis Format",
    any: "Apa Saja"
  }

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Tukar Koleksi GLAM Indonesia")
     |> assign(:tab, :offers)
     |> assign(:search, "")
     |> assign(:province, nil)
     |> assign(:page_offers, 1)
     |> assign(:page_wishlists, 1)
     |> assign(:offers_count, 0)
     |> assign(:wishlists_count, 0)
     |> assign(:has_more_offers, false)
     |> assign(:has_more_wishlists, false)
     |> assign(:condition_labels, @condition_labels)
     |> assign(:specificity_labels, @specificity_labels)}
  end

  def handle_params(params, _uri, socket) do
    tab = if Map.get(params, "tab") == "wishlist", do: :wishlists, else: :offers
    q = Map.get(params, "q", "")
    province = Map.get(params, "province", nil) |> empty_to_nil()
    offers_page = String.to_integer(Map.get(params, "offers_page", "1"))
    wishlists_page = String.to_integer(Map.get(params, "wishlists_page", "1"))

    offers = Public.list_exchange_offers(search: q, province: province, page: offers_page)
    wishlists = Public.list_exchange_wishlists(search: q, page: wishlists_page)

    {:noreply,
     socket
     |> assign(:tab, tab)
     |> assign(:search, q)
     |> assign(:province, province)
     |> assign(:page_offers, offers_page)
     |> assign(:page_wishlists, wishlists_page)
     |> assign(:offers_count, length(offers))
     |> assign(:wishlists_count, length(wishlists))
     |> assign(:has_more_offers, length(offers) == Public.page_size())
     |> assign(:has_more_wishlists, length(wishlists) == Public.page_size())
     |> stream(:offers, offers, reset: true)
     |> stream(:wishlists, wishlists, reset: true)}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    params = build_params(socket.assigns.search, socket.assigns.province, tab, 1, 1)
    {:noreply, push_patch(socket, to: ~p"/exchange?#{params}")}
  end

  def handle_event("search", %{"q" => q}, socket) do
    tab = if socket.assigns.tab == :wishlists, do: "wishlist", else: "offers"
    params = build_params(q, socket.assigns.province, tab, 1, 1)
    {:noreply, push_patch(socket, to: ~p"/exchange?#{params}")}
  end

  def handle_event("filter", %{"province" => province}, socket) do
    tab = if socket.assigns.tab == :wishlists, do: "wishlist", else: "offers"
    params = build_params(socket.assigns.search, empty_to_nil(province), tab, 1, 1)
    {:noreply, push_patch(socket, to: ~p"/exchange?#{params}")}
  end

  def handle_event("load_more_offers", _, socket) do
    next_page = socket.assigns.page_offers + 1

    offers =
      Public.list_exchange_offers(
        search: socket.assigns.search,
        province: socket.assigns.province,
        page: next_page
      )

    {:noreply,
     socket
     |> assign(:page_offers, next_page)
     |> assign(:offers_count, socket.assigns.offers_count + length(offers))
     |> assign(:has_more_offers, length(offers) == Public.page_size())
     |> stream(:offers, offers)}
  end

  def handle_event("load_more_wishlists", _, socket) do
    next_page = socket.assigns.page_wishlists + 1

    wishlists =
      Public.list_exchange_wishlists(
        search: socket.assigns.search,
        page: next_page
      )

    {:noreply,
     socket
     |> assign(:page_wishlists, next_page)
     |> assign(:wishlists_count, socket.assigns.wishlists_count + length(wishlists))
     |> assign(:has_more_wishlists, length(wishlists) == Public.page_size())
     |> stream(:wishlists, wishlists)}
  end

  defp build_params(search, province, tab, offers_page, wishlists_page) do
    %{}
    |> then(fn m -> if search != "", do: Map.put(m, "q", search), else: m end)
    |> then(fn m -> if province, do: Map.put(m, "province", province), else: m end)
    |> then(fn m -> if tab != "offers", do: Map.put(m, "tab", tab), else: m end)
    |> then(fn m ->
      if offers_page > 1, do: Map.put(m, "offers_page", to_string(offers_page)), else: m
    end)
    |> then(fn m ->
      if wishlists_page > 1, do: Map.put(m, "wishlists_page", to_string(wishlists_page)), else: m
    end)
  end

  defp empty_to_nil(nil), do: nil
  defp empty_to_nil(""), do: nil
  defp empty_to_nil(val), do: val

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <%!-- Hero --%>
      <div class="bg-gradient-to-br from-secondary/10 via-base-100 to-primary/5 border-b border-base-300">
        <div class="max-w-6xl mx-auto px-4 py-14 text-center">
          <div class="inline-flex items-center gap-2 bg-secondary/10 text-secondary px-4 py-1.5 rounded-full text-sm font-medium mb-4">
            <.icon name="hero-arrows-right-left" class="size-4" /> Tukar Koleksi
          </div>
          <h1 class="text-3xl sm:text-5xl font-bold text-base-content mb-4 leading-tight">
            Salurkan Koleksi<br />
            <span class="text-secondary">ke Tangan yang Tepat</span>
          </h1>
          <p class="text-lg text-base-content/60 max-w-2xl mx-auto">
            Tawarkan koleksi yang ingin disalurkan, atau temukan koleksi yang sedang dibutuhkan institusi GLAM di seluruh Indonesia.
          </p>
          <%= if is_nil(@current_scope) do %>
            <div class="mt-6">
              <.link
                navigate="/login?return_to=/exchange"
                class="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-secondary text-secondary-content font-semibold hover:bg-secondary/90 transition"
              >
                <.icon name="hero-user-plus" class="size-4" /> Bergabung & Tawarkan Koleksi
              </.link>
            </div>
          <% end %>
        </div>
      </div>

      <div class="max-w-6xl mx-auto py-8 px-4">
        <%!-- Tabs + Search + Filter --%>
        <div class="flex flex-col sm:flex-row gap-3 items-start sm:items-center mb-6">
          <div class="flex rounded-xl border border-base-300 overflow-hidden shrink-0">
            <button
              phx-click="switch_tab"
              phx-value-tab="offers"
              class={[
                "px-5 py-2 text-sm font-medium transition",
                @tab == :offers && "bg-primary text-primary-content",
                @tab != :offers && "bg-base-100 text-base-content hover:bg-base-200"
              ]}
            >
              Penawaran
            </button>
            <button
              phx-click="switch_tab"
              phx-value-tab="wishlist"
              class={[
                "px-5 py-2 text-sm font-medium transition",
                @tab == :wishlists && "bg-secondary text-secondary-content",
                @tab != :wishlists && "bg-base-100 text-base-content hover:bg-base-200"
              ]}
            >
              Wishlist
            </button>
          </div>

          <form phx-change="filter" class="flex flex-1 gap-3">
            <input
              type="text"
              name="q"
              value={@search}
              placeholder={if @tab == :offers, do: "Cari item koleksi...", else: "Cari wishlist..."}
              class="flex-1 border border-base-300 rounded-xl px-4 py-2 text-sm focus:border-primary focus:outline-none"
              phx-debounce="300"
              phx-keyup="search"
            />
            <%= if @tab == :offers do %>
              <input
                type="text"
                name="province"
                value={@province || ""}
                placeholder="Provinsi..."
                class="w-40 border border-base-300 rounded-xl px-3 py-2 text-sm focus:border-primary focus:outline-none"
                phx-debounce="300"
              />
            <% end %>
          </form>
        </div>

        <%!-- Offers Tab --%>
        <%= if @tab == :offers do %>
          <div
            id="offers"
            phx-update="stream"
            class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5"
          >
            <div :for={{id, offer} <- @streams.offers} id={id}>
              <.offer_card
                offer={offer}
                condition_labels={@condition_labels}
                current_scope={@current_scope}
              />
            </div>
          </div>

          <div
            :if={@offers_count == 0}
            class="py-16 text-center text-base-content/60 border border-base-300 rounded-2xl"
          >
            <.icon name="hero-archive-box" class="size-12 mx-auto mb-3 opacity-40" />
            <p class="text-lg font-medium">Belum ada penawaran saat ini.</p>
            <p class="text-sm mt-1">Jadilah yang pertama menawarkan koleksi.</p>
          </div>

          <div :if={@has_more_offers} class="flex justify-center mt-8">
            <button
              phx-click="load_more_offers"
              class="px-6 py-2 rounded-full border border-secondary text-secondary hover:bg-secondary hover:text-secondary-content transition"
            >
              Muat lebih banyak
            </button>
          </div>
        <% end %>

        <%!-- Wishlist Tab --%>
        <%= if @tab == :wishlists do %>
          <div
            id="wishlists"
            phx-update="stream"
            class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5"
          >
            <div :for={{id, wish} <- @streams.wishlists} id={id}>
              <.wishlist_card
                wish={wish}
                specificity_labels={@specificity_labels}
                current_scope={@current_scope}
              />
            </div>
          </div>

          <div
            :if={@wishlists_count == 0}
            class="py-16 text-center text-base-content/60 border border-base-300 rounded-2xl"
          >
            <.icon name="hero-clipboard-document-list" class="size-12 mx-auto mb-3 opacity-40" />
            <p class="text-lg font-medium">Belum ada wishlist saat ini.</p>
            <p class="text-sm mt-1">Log masuk untuk menambahkan wishlist koleksi Anda.</p>
          </div>

          <div :if={@has_more_wishlists} class="flex justify-center mt-8">
            <button
              phx-click="load_more_wishlists"
              class="px-6 py-2 rounded-full border border-secondary text-secondary hover:bg-secondary hover:text-secondary-content transition"
            >
              Muat lebih banyak
            </button>
          </div>
        <% end %>

        <%!-- Join CTA --%>
        <div class="mt-16 bg-gradient-to-br from-primary/5 to-secondary/5 border border-base-300 rounded-2xl p-8 text-center">
          <.icon name="hero-arrows-right-left" class="size-10 text-secondary mx-auto mb-3" />
          <h2 class="text-xl font-bold text-base-content mb-2">Punya koleksi untuk disalurkan?</h2>
          <p class="text-sm text-base-content/60 mb-5 max-w-md mx-auto">
            Daftarkan institusi atau akun pribadi Anda dan mulai menawarkan koleksi kepada institusi yang membutuhkan.
          </p>
          <%= if @current_scope do %>
            <.link
              navigate="/in/exchange"
              class="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-secondary text-secondary-content font-semibold hover:bg-secondary/90 transition"
            >
              <.icon name="hero-plus" class="size-4" /> Tambah Penawaran
            </.link>
          <% else %>
            <.link
              navigate="/login?return_to=/exchange"
              class="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-secondary text-secondary-content font-semibold hover:bg-secondary/90 transition"
            >
              <.icon name="hero-arrow-right-end-on-rectangle" class="size-4" />
              Masuk untuk Berpartisipasi
            </.link>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp offer_card(assigns) do
    assigns =
      assign(
        assigns,
        :condition_label,
        Map.get(assigns.condition_labels, assigns.offer.item_condition, "-")
      )

    ~H"""
    <article class="bg-base-100 rounded-2xl border border-base-300 shadow-sm hover:shadow-lg transition flex flex-col">
      <%!-- Type accent bar --%>
      <div class="h-1.5 rounded-t-2xl bg-gradient-to-r from-secondary to-primary"></div>

      <div class="p-5 flex flex-col flex-1">
        <%!-- Badges --%>
        <div class="flex flex-wrap gap-2 mb-3">
          <span class="badge badge-sm bg-base-200 text-base-content">
            {@offer.item_type || "Koleksi"}
          </span>
          <span class={[
            "badge badge-sm font-medium",
            @offer.item_condition in [:new, :very_good] && "bg-green-100 text-green-800",
            @offer.item_condition == :good && "bg-blue-100 text-blue-800",
            @offer.item_condition in [:fair, :poor] && "bg-yellow-100 text-yellow-800"
          ]}>
            {@condition_label}
          </span>
        </div>

        <h2 class="text-base font-semibold text-base-content leading-snug mb-1">
          {@offer.item_title}
        </h2>

        <p :if={@offer.item_description} class="text-sm text-base-content/60 line-clamp-2 mb-3">
          {@offer.item_description}
        </p>

        <p :if={@offer.suitability_note} class="text-xs text-base-content/50 italic mb-3">
          "{@offer.suitability_note}"
        </p>

        <div class="mt-auto pt-3 border-t border-base-200 text-xs text-base-content/60 space-y-1">
          <p :if={@offer.available_city || @offer.available_province}>
            <.icon name="hero-map-pin" class="size-3 inline mr-0.5" />
            {[@offer.available_city, @offer.available_province]
            |> Enum.reject(&is_nil/1)
            |> Enum.join(", ")}
          </p>
          <p>
            <.icon name="hero-cube" class="size-3 inline mr-0.5" /> {@offer.item_quantity || 1} item tersedia
          </p>
        </div>

        <%= if @current_scope do %>
          <button
            disabled
            class="mt-4 w-full py-2 rounded-xl bg-secondary/80 text-secondary-content text-sm font-semibold opacity-60 cursor-not-allowed"
          >
            Saya Tertarik (Segera Hadir)
          </button>
        <% else %>
          <.link
            navigate="/login?return_to=/exchange"
            class="mt-4 inline-flex items-center justify-center w-full py-2 rounded-xl border border-secondary text-secondary text-sm font-semibold hover:bg-secondary hover:text-secondary-content transition"
          >
            Masuk untuk Hubungi
          </.link>
        <% end %>
      </div>
    </article>
    """
  end

  defp wishlist_card(assigns) do
    assigns =
      assign(
        assigns,
        :specificity_label,
        Map.get(assigns.specificity_labels, assigns.wish.specificity, "-")
      )

    ~H"""
    <article class="bg-base-100 rounded-2xl border border-base-300 shadow-sm hover:shadow-lg transition flex flex-col">
      <%!-- Type accent bar --%>
      <div class="h-1.5 rounded-t-2xl bg-gradient-to-r from-primary to-secondary"></div>

      <div class="p-5 flex flex-col flex-1">
        <%!-- Badges --%>
        <div class="flex flex-wrap gap-2 mb-3">
          <span class="badge badge-sm bg-base-200 text-base-content">
            {@wish.item_type || "Koleksi"}
          </span>
          <span class="badge badge-sm bg-primary/10 text-primary">
            {@specificity_label}
          </span>
        </div>

        <h2 class="text-base font-semibold text-base-content leading-snug mb-1">
          {if @wish.item_title && @wish.item_title != "", do: @wish.item_title, else: "Pencarian Umum"}
        </h2>

        <p :if={@wish.subject_area} class="text-xs text-base-content/50 mb-1">
          Subjek: {@wish.subject_area}
        </p>

        <p :if={@wish.description} class="text-sm text-base-content/60 line-clamp-2 mb-3">
          {@wish.description}
        </p>

        <div class="mt-auto pt-3 border-t border-base-200 text-xs text-base-content/60 space-y-1">
          <p :if={@wish.preferred_province}>
            <.icon name="hero-map-pin" class="size-3 inline mr-0.5" />
            Provinsi: {@wish.preferred_province}
          </p>
          <p>
            <.icon name="hero-clipboard-document-list" class="size-3 inline mr-0.5" />
            Dibutuhkan: {@wish.quantity_needed || 1} item
          </p>
        </div>

        <%= if @current_scope do %>
          <button
            disabled
            class="mt-4 w-full py-2 rounded-xl bg-primary/80 text-primary-content text-sm font-semibold opacity-60 cursor-not-allowed"
          >
            Tawarkan Kecocokan (Segera Hadir)
          </button>
        <% else %>
          <.link
            navigate="/login?return_to=/exchange"
            class="mt-4 inline-flex items-center justify-center w-full py-2 rounded-xl border border-primary text-primary text-sm font-semibold hover:bg-primary hover:text-primary-content transition"
          >
            Masuk untuk Merespons
          </.link>
        <% end %>
      </div>
    </article>
    """
  end
end
