defmodule CuratorianWeb.Public.CollectionsExternal do
  @moduledoc """
  The external-sources section of the collections page (spec §6A.7, §10).

  Visually distinct from local results so users always know what is
  Curatorian's and what is not: tinted `ext-panel` with an `ext-accent` edge,
  per-provider shelves (horizontal scroll-snap), access badges (icon + text,
  never color alone) and per-provider status blocks.
  """

  use Phoenix.Component

  import CuratorianWeb.CoreComponents, only: [icon: 1]

  @hues [10, 35, 145, 178, 215, 335]

  @kind_labels %{
    book: "Buku",
    article: "Artikel ilmiah",
    image: "Gambar",
    artwork: "Karya seni",
    audio: "Audio",
    video: "Video",
    archive: "Arsip",
    other: "Lainnya"
  }

  attr :blocks, :list, required: true
  attr :notice, :any, default: nil
  attr :promoted, :boolean, default: false
  attr :hidden_count, :integer, default: 0
  attr :privacy_url, :string, default: "/privacy-policy"
  attr :openalex_budget, :atom, default: :ok
  attr :article_url, :string, default: nil

  def section(assigns) do
    ~H"""
    <section id="external-results" aria-labelledby="external-heading" class="mt-10">
      <div class="ext-panel p-4 sm:p-6">
        <h2 id="external-heading" class="text-lg sm:text-xl font-semibold m-0">
          <%= if @promoted do %>
            Tidak ditemukan di Curatorian. Hasil dari sumber terbuka lain:
          <% else %>
            Dari sumber terbuka lain
          <% end %>
        </h2>
        <p class="text-sm text-base-content/60 mt-1 mb-4">
          Hasil berikut berasal dari layanan pihak ketiga, bukan koleksi Curatorian.
        </p>

        <p
          :if={match?({:summary, _, _}, @notice)}
          class="mb-4 inline-flex items-center gap-2 rounded-lg border border-base-300/70 bg-base-100 px-3 py-2 text-sm"
          role="status"
        >
          <.icon name="hero-clock" class="size-4 shrink-0 access-borrow" />
          <span>
            <%= case @notice do %>
              <% {:summary, limited, total} -> %>
                {limited} dari {total} sumber sedang dibatasi. Hasil dari Curatorian tidak terpengaruh.
              <% _ -> %>
            <% end %>
          </span>
        </p>

        <p
          :if={@notice == :visitor_limited}
          class="mb-4 rounded-lg border border-warning/30 bg-base-100 px-3 py-2 text-sm"
          role="status"
        >
          Anda mencari terlalu cepat. Pencarian di sumber luar dilanjutkan sebentar lagi.
        </p>

        <div
          :if={@openalex_budget in [:degraded, :exhausted] and @article_url}
          class="mb-4 flex flex-wrap items-center gap-2 rounded-lg border border-base-300/70 bg-base-100 px-3 py-2 text-sm"
          role="status"
        >
          <.icon name="hero-clock" class="size-4 shrink-0 access-borrow" />
          <span class="mr-auto">
            Pencarian artikel ilmiah dibatasi sementara karena kuota harian.
          </span>
          <.link patch={@article_url} class="btn btn-outline btn-sm">Cari artikel ilmiah</.link>
        </div>

        <p
          :if={@hidden_count > 0}
          class="mb-3 text-xs text-base-content/50"
          title="Hasil yang sama muncul di lebih dari satu sumber"
        >
          {format_count(@hidden_count)} hasil ganda antar-sumber disembunyikan.
        </p>

        <div class="space-y-3">
          <.provider_block :for={block <- @blocks} block={block} />
        </div>

        <p class="mt-5 text-xs text-base-content/50">
          Kata kunci pencarian Anda akan dikirim ke layanan pihak ketiga yang dipilih.
          <.link navigate={@privacy_url} class="underline underline-offset-2 hover:text-primary">
            Kebijakan privasi
          </.link>
        </p>
      </div>
    </section>
    """
  end

  attr :block, :map, required: true

  defp provider_block(assigns) do
    article_rows? =
      assigns.block.results != [] and Enum.all?(assigns.block.results, &(&1.kind == :article))

    assigns = assign(assigns, :article_rows?, article_rows?)

    ~H"""
    <details class="ext-block border-t border-base-300/50 pt-2" open>
      <summary class="flex cursor-pointer list-none items-center gap-2 py-2">
        <span class="ext-accent font-semibold">{@block.label}</span>
        <.block_status_inline state={@block.state} total={Map.get(@block, :total)} />
      </summary>

      <div class="pb-2">
        <%= case @block.state do %>
          <% :loading -> %>
            <div class="ext-shelf" aria-hidden="true">
              <div :for={_i <- 1..5} class="ext-card">
                <div class="skeleton aspect-[3/4] rounded"></div>
                <div class="skeleton mt-2 h-3 w-4/5"></div>
                <div class="skeleton mt-1 h-3 w-3/5"></div>
              </div>
            </div>
          <% state when state in [:ok, :cache_hit, :stale] -> %>
            <p
              :if={state == :stale}
              class="mb-2 inline-flex items-center gap-1.5 text-xs access-borrow"
            >
              <.icon name="hero-clock" class="size-3.5" />
              Menampilkan hasil tersimpan {Map.get(@block, :stale_age_min)} menit lalu.
            </p>

            <p :if={@block.results == []} class="text-sm text-base-content/60">
              Tidak ada hasil di {@block.label}.
            </p>

            <%!-- Articles/text-only sources render as compact rows (§6A.7) --%>
            <ul
              :if={@block.results != [] and @article_rows?}
              class="divide-y divide-base-300/40 list-none m-0 p-0"
            >
              <.article_row :for={result <- @block.results} result={result} />
            </ul>

            <ul :if={@block.results != [] and !@article_rows?} class="ext-shelf">
              <.ext_card :for={result <- @block.results} result={result} />
            </ul>
          <% :empty -> %>
            <p class="text-sm text-base-content/60">Tidak ada hasil di {@block.label}.</p>
          <% :rate_limited -> %>
            <div class="status-block" role="status">
              <p class="text-sm">
                {@block.label} sedang dibatasi sementara.
                <span :if={Map.get(@block, :retry_after)}>
                  Coba lagi dalam {Map.get(@block, :retry_after)} detik.
                </span>
              </p>
              <div class="mt-2 flex flex-wrap items-center gap-2">
                <button
                  phx-click="retry_provider"
                  phx-value-provider={@block.id}
                  disabled={Map.get(@block, :retry_after)}
                  class="btn btn-sm btn-outline"
                >
                  Coba lagi
                </button>
                <a
                  :if={Map.get(@block, :more_url)}
                  href={@block.more_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="link link-hover text-sm font-medium"
                >
                  Cari langsung di {@block.label}
                  <.icon name="hero-arrow-top-right-on-square" class="size-3.5" />
                  <span class="sr-only">(buka di tab baru)</span>
                </a>
              </div>
            </div>
          <% :budget -> %>
            <div class="status-block" role="status">
              <p class="text-sm">
                {@block.label} dibatasi sampai {format_reset(Map.get(@block, :resets_at))} WIB.
              </p>
              <a
                :if={Map.get(@block, :more_url)}
                href={@block.more_url}
                target="_blank"
                rel="noopener noreferrer"
                class="link link-hover mt-2 inline-flex items-center gap-1 text-sm font-medium"
              >
                Cari langsung di {@block.label}
                <.icon name="hero-arrow-top-right-on-square" class="size-3.5" />
                <span class="sr-only">(buka di tab baru)</span>
              </a>
            </div>
          <% :breaker_open -> %>
            <p class="text-sm text-base-content/60" role="status">
              {@block.label} sedang tidak tersedia.
            </p>
          <% :disabled -> %>
            <p class="text-sm text-base-content/60">Sumber ini sedang dinonaktifkan.</p>
          <% _ -> %>
            <div class="status-block" role="status">
              <p class="text-sm">{@block.label} belum merespons.</p>
              <button
                phx-click="retry_provider"
                phx-value-provider={@block.id}
                class="btn btn-sm btn-outline mt-2"
              >
                Coba lagi
              </button>
            </div>
        <% end %>
      </div>

      <.link
        :if={Map.get(@block, :more_from_url)}
        patch={@block.more_from_url}
        class="ext-accent mb-1 inline-flex items-center gap-1 text-sm font-medium hover:underline"
      >
        Lihat lebih banyak dari {@block.label}
        <.icon name="hero-arrow-right" class="size-3.5" />
      </.link>

      <a
        :if={Map.get(@block, :more_url)}
        href={@block.more_url}
        target="_blank"
        rel="noopener noreferrer"
        class="ext-accent mb-2 inline-flex items-center gap-1.5 text-sm font-medium hover:underline"
      >
        Lihat semua hasil di {@block.label}
        <.icon name="hero-arrow-top-right-on-square" class="size-3.5" />
        <span class="sr-only">(buka di tab baru)</span>
      </a>
    </details>
    """
  end

  attr :state, :atom, required: true
  attr :total, :any, default: nil

  defp block_status_inline(assigns) do
    ~H"""
    <small class="ml-auto text-xs text-base-content/50">
      <%= cond do %>
        <% @state == :loading -> %>
          memuat…
        <% @state in [:ok, :cache_hit] and is_integer(@total) -> %>
          {format_count(@total)} hasil
        <% @state in [:ok, :cache_hit, :stale] -> %>
          hasil
        <% @state == :rate_limited -> %>
          dibatasi
        <% @state == :breaker_open -> %>
          tidak tersedia
        <% @state == :empty -> %>
          kosong
        <% true -> %>
          belum merespons
      <% end %>
    </small>
    """
  end

  attr :result, :map, required: true

  defp ext_card(assigns) do
    ~H"""
    <li class="ext-card">
      <a
        href={@result.url}
        target="_blank"
        rel="noopener noreferrer"
        class="group block"
        title={@result.title}
      >
        <div
          id={cover_dom_id(@result)}
          class="relative aspect-[3/4] overflow-hidden rounded border border-base-300/70 bg-base-200"
          phx-hook="CoverFallback"
          data-hue={hue_for(@result.source_id)}
          data-title={@result.title}
          data-org={creator_line(@result)}
          data-type={kind_label(@result.kind)}
        >
          <img
            :if={@result.thumbnail_url}
            src={@result.thumbnail_url}
            alt=""
            width="144"
            height="192"
            loading="lazy"
            referrerpolicy="no-referrer"
            class="absolute inset-0 size-full object-cover"
          />
          <div
            :if={!@result.thumbnail_url}
            class="cover-placeholder"
            style={"--h: #{hue_for(@result.source_id)}"}
          >
            <small>{kind_label(@result.kind)}</small>
            <span>{@result.title}</span>
            <small>{creator_line(@result)}</small>
          </div>
        </div>
        <p class="mt-1.5 text-sm font-semibold leading-snug line-clamp-2" dir="auto">
          {@result.title}
          <span class="sr-only">(buka di tab baru)</span>
        </p>
      </a>
      <p class="text-xs text-base-content/60 truncate" dir="auto">{creator_line(@result)}</p>
      <.access_badge access={@result.access} rights={@result.rights} />
    </li>
    """
  end

  attr :result, :map, required: true

  defp article_row(assigns) do
    ~H"""
    <li class="py-2.5">
      <a
        href={@result.url}
        target="_blank"
        rel="noopener noreferrer"
        class="font-semibold text-base-content hover:text-primary hover:underline underline-offset-2"
        dir="auto"
      >
        {@result.title}
        <span class="sr-only">(buka di tab baru)</span>
      </a>
      <p class="text-xs text-base-content/60 mt-0.5">{article_meta(@result)}</p>
      <div class="mt-1 flex flex-wrap items-center gap-x-3 gap-y-1">
        <.access_badge access={@result.access} rights={@result.rights} />
        <span :if={@result.identifiers[:doi]} class="text-[11px] text-base-content/40">
          DOI {@result.identifiers[:doi]}
        </span>
      </div>
    </li>
    """
  end

  attr :access, :atom, required: true
  attr :rights, :string, default: nil

  defp access_badge(assigns) do
    ~H"""
    <span
      :if={@access == :open}
      class="access-open mt-1 inline-flex items-center gap-1 text-[11px] font-medium"
    >
      <.icon name="hero-check-circle" class="size-3" /> Akses terbuka
    </span>
    <span
      :if={@access == :borrowable}
      class="access-borrow mt-1 inline-flex items-center gap-1 text-[11px] font-medium"
    >
      <.icon name="hero-clock" class="size-3" /> Bisa dipinjam
    </span>
    <span
      :if={@access == :restricted}
      class="access-borrow mt-1 inline-flex items-center gap-1 text-[11px] font-medium"
    >
      <.icon name="hero-lock-closed" class="size-3" /> Terbatas
    </span>
    <span :if={@rights} class="block text-[11px] text-base-content/50 truncate">{@rights}</span>
    """
  end

  # --- helpers ---

  defp creator_line(%{creators: creators}) when is_list(creators) and creators != [] do
    case creators do
      [one] -> one
      [a, b] -> "#{a}, #{b}"
      [a, b, c | rest] -> if rest == [], do: "#{a}, #{b}, #{c}", else: "#{a}, #{b}, #{c} dkk."
    end
  end

  defp creator_line(_), do: ""

  defp kind_label(kind), do: Map.get(@kind_labels, kind, "Lainnya")

  defp article_meta(result) do
    parts =
      [creator_line(result), result.year, result.extra[:venue]]
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.map(&to_string/1)

    Enum.join(parts, ", ")
  end

  defp format_reset(nil), do: "waktu reset"

  defp format_reset(unix) when is_integer(unix) do
    unix
    |> DateTime.from_unix!()
    |> DateTime.add(7, :hour)
    |> Calendar.strftime("%d/%m %H.%M")
  end

  defp hue_for(id), do: Enum.at(@hues, rem(:erlang.phash2(id), length(@hues)))

  defp cover_dom_id(result) do
    safe = String.replace(result.source_id, ~r/[^A-Za-z0-9_-]/, "-")
    "ext-cover-#{result.source}-#{safe}"
  end

  defp format_count(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.replace(~r/(\d)(?=(\d{3})+$)/, "\\1.")
  end

  defp format_count(_), do: ""
end
