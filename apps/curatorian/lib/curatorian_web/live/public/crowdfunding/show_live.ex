defmodule CuratorianWeb.Public.Crowdfunding.ShowLive do
  @moduledoc "Public crowdfunding campaign detail page (/crowdfunding/:slug)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  def mount(%{"slug" => slug}, _session, socket) do
    case Public.get_campaign_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Kampanye tidak ditemukan atau sudah tidak aktif.")
         |> push_navigate(to: "/crowdfunding")}

      campaign ->
        {:ok,
         socket
         |> assign(:page_title, "#{campaign.title} — Crowdfunding")
         |> assign(:campaign, campaign)}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-5xl mx-auto py-8 px-4 space-y-6">
        <.link navigate="/crowdfunding" class="text-sm text-base-content/60 hover:text-base-content">
          <.icon name="hero-arrow-left" class="size-4" /> Kembali ke daftar kampanye
        </.link>

        <%!-- Header --%>
        <header class="bg-base-100 border border-base-300 rounded-2xl overflow-hidden">
          <%= if @campaign.cover_image_url do %>
            <div class="aspect-[3/1] overflow-hidden">
              <img
                src={@campaign.cover_image_url}
                alt={@campaign.title}
                class="w-full h-full object-cover"
              />
            </div>
          <% else %>
            <div class="aspect-[3/1] bg-gradient-to-br from-primary/20 to-secondary/10 flex items-center justify-center">
              <.icon name="hero-heart" class="size-16 text-primary/30" />
            </div>
          <% end %>

          <div class="p-6">
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
              <span class="badge badge-sm bg-base-200 text-success">
                Aktif
              </span>
            </div>
            <h1 class="text-2xl sm:text-3xl font-bold text-base-content">{@campaign.title}</h1>
          </div>
        </header>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <%!-- Main Content --%>
          <section class="lg:col-span-2 space-y-5">
            <article class="bg-base-100 border border-base-300 rounded-2xl p-6">
              <h2 class="text-sm font-semibold text-base-content mb-3">Tentang Kampanye</h2>
              <div class="whitespace-pre-line text-sm text-base-content/80 leading-relaxed">
                {@campaign.description || "Deskripsi belum tersedia."}
              </div>
            </article>

            <%= if @campaign.campaign_type in [:collection_items, :mixed] and @campaign.item_goal_description do %>
              <article class="bg-base-100 border border-base-300 rounded-2xl p-6">
                <h2 class="text-sm font-semibold text-base-content mb-3">Item yang Dibutuhkan</h2>
                <div class="whitespace-pre-line text-sm text-base-content/80 leading-relaxed">
                  {@campaign.item_goal_description}
                </div>
              </article>
            <% end %>
          </section>

          <%!-- Sidebar --%>
          <aside class="space-y-4">
            <%!-- Money Progress --%>
            <%= if @campaign.campaign_type in [:money, :mixed] and @campaign.goal_amount_idr do %>
              <div class="bg-base-100 border border-base-300 rounded-2xl p-5 space-y-3">
                <h3 class="text-sm font-semibold text-base-content">Progress Dana</h3>
                <div>
                  <div class="flex justify-between text-xs text-base-content/60 mb-1">
                    <span>Terkumpul</span>
                    <span class="font-semibold text-primary">
                      {money_percent(@campaign)}%
                    </span>
                  </div>
                  <div class="w-full bg-base-200 rounded-full h-2.5">
                    <div
                      class="bg-primary rounded-full h-2.5 transition-all"
                      style={"width: #{min(money_percent(@campaign), 100)}%"}
                    >
                    </div>
                  </div>
                  <div class="flex justify-between text-sm mt-2">
                    <span class="font-bold text-base-content">
                      {format_idr(@campaign.raised_amount_idr || 0)}
                    </span>
                    <span class="text-base-content/60">
                      dari {format_idr(@campaign.goal_amount_idr)}
                    </span>
                  </div>
                </div>
                <p class="text-xs text-base-content/50 text-center">
                  {@campaign.donor_count || 0} donatur telah berkontribusi
                </p>
              </div>
            <% end %>

            <%!-- Items Progress --%>
            <%= if @campaign.campaign_type in [:collection_items, :mixed] and @campaign.item_goal_count do %>
              <div class="bg-base-100 border border-base-300 rounded-2xl p-5 space-y-3">
                <h3 class="text-sm font-semibold text-base-content">Progress Item Koleksi</h3>
                <div>
                  <div class="flex justify-between text-xs text-base-content/60 mb-1">
                    <span>Diterima</span>
                    <span class="font-semibold text-secondary">
                      {items_percent(@campaign)}%
                    </span>
                  </div>
                  <div class="w-full bg-base-200 rounded-full h-2.5">
                    <div
                      class="bg-secondary rounded-full h-2.5 transition-all"
                      style={"width: #{min(items_percent(@campaign), 100)}%"}
                    >
                    </div>
                  </div>
                  <div class="flex justify-between text-sm mt-2">
                    <span class="font-bold text-base-content">
                      {@campaign.item_received_count || 0} item
                    </span>
                    <span class="text-base-content/60">dari {@campaign.item_goal_count} target</span>
                  </div>
                </div>
              </div>
            <% end %>

            <%!-- Campaign Info --%>
            <div class="bg-base-100 border border-base-300 rounded-2xl p-4 space-y-2 text-sm text-base-content/80">
              <%= if @campaign.starts_at do %>
                <p>
                  <strong>Mulai:</strong>
                  {format_date(@campaign.starts_at)}
                </p>
              <% end %>
              <%= if @campaign.ends_at do %>
                <p>
                  <strong>Berakhir:</strong>
                  {format_date(@campaign.ends_at)}
                </p>
              <% end %>
              <%= if @campaign.is_permanent do %>
                <p class="text-green-700 font-medium">Kampanye berlangsung permanen</p>
              <% end %>
            </div>

            <%!-- Donate CTA --%>
            <div class="bg-primary/5 border border-primary/20 rounded-2xl p-5 text-center">
              <.icon name="hero-heart" class="size-8 text-primary mx-auto mb-2" />
              <p class="text-sm text-base-content/70 mb-3">
                Dukung kampanye ini dan bantu warisan pengetahuan Indonesia.
              </p>
              <%= if @current_scope do %>
                <button
                  disabled
                  class="w-full py-2.5 rounded-xl bg-primary text-primary-content text-sm font-semibold opacity-60 cursor-not-allowed"
                >
                  Donasi (Segera Hadir)
                </button>
              <% else %>
                <.link
                  navigate={"/login?return_to=/crowdfunding/#{@campaign.slug}"}
                  class="inline-flex items-center justify-center w-full py-2.5 rounded-xl bg-primary text-primary-content text-sm font-semibold hover:bg-primary/90 transition"
                >
                  Masuk untuk Berdonasi
                </.link>
              <% end %>
            </div>
          </aside>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp money_percent(%{raised_amount_idr: raised, goal_amount_idr: goal})
       when is_integer(raised) and is_integer(goal) and goal > 0 do
    round(raised / goal * 100)
  end

  defp money_percent(_), do: 0

  defp items_percent(%{item_received_count: received, item_goal_count: goal})
       when is_integer(received) and is_integer(goal) and goal > 0 do
    round(received / goal * 100)
  end

  defp items_percent(_), do: 0

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

  defp format_date(nil), do: "-"

  defp format_date(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
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
