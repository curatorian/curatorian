defmodule CuratorianWeb.Public.CollectionsLive do
  @moduledoc """
  Flagship cross-node collection discovery page (/collections) — Phase C1 of
  the collections search spec.

  URL-addressable search over every published, public collection in the
  network. Data comes from `Curatorian.Public` over the shared Postgres schema
  (hybrid decision — the Atrium HTTP client arrives with Phase C2/C3).

  Spec mapping (Section 6 / 6A):

  * URL contract §6.1 — `q`, `sector`, `org`, `type`, `lang`, `prov`, `city`,
    `subject`, `sort`, `page`, `view`. Legacy pre-C1 names (`glam_type`,
    `node_id`, `province`, `language`) are accepted when *reading* the URL but
    never written, so old shared links keep working while new URLs already
    match the future Atrium API contract. Unknown params are ignored.
  * Data access §6.2 — one navigation runs count → (clamp) → page query; facets
    are only recomputed on page 1 and kept on page changes (equivalent of
    `facets=none`). Out-of-range pages clamp to the last page instead of
    erroring.
  * Display safeguards §5 — trim values, hide facet groups with fewer than 2
    distinct values, format counts `id-ID` (`1.043`, never `2rb`); no client
    side merging of dirty facet values (that is Atrium phase A3).
  * Search header §6A.5.1 — debounced (300 ms) live local results; explicit
    submit (Enter / "Cari") is the Phase C2 trigger point for external
    federation (spec D4).
  * SEO §6.3 — any URL with `q` gets `noindex, follow`; browse URLs stay
    indexable.
  * Visual identity — the site's existing daisyUI tokens and fonts (§6A.1
    "reuse before inventing"), not the mockup's palette.
  """

  use CuratorianWeb, :live_view

  require Logger

  alias Curatorian.Public
  alias Curatorian.RateLimiter
  alias Curatorian.Search.Federation.{Budget, Dedupe, Federator, Router}
  alias Curatorian.Search.Query
  alias CuratorianWeb.Pagination
  alias CuratorianWeb.Public.CollectionsExternal

  @list_page_size 12
  # Rich cards are visually heavy — the old page shipped 12 per page and that
  # density is right for them (24 was sized for the small-tile grid).
  @grid_page_size 12
  @max_page_size 48
  @max_q_length 200
  @facet_top_n 8

  # Filter keys → URL param names (spec §6.1).
  @filter_to_param %{
    q: "q",
    glam_type: "sector",
    node_id: "org",
    type: "type",
    institution_type: "institution_type",
    city: "city",
    province: "prov",
    language: "lang",
    subject: "subject",
    creator: "creator",
    has_ebook: "has_ebook"
  }

  @param_to_filter Map.new(@filter_to_param, fn {key, param} -> {param, key} end)

  # Legacy names written by the pre-C1 page; normalized on read only.
  @legacy_params %{
    "glam_type" => "sector",
    "node_id" => "org",
    "province" => "prov",
    "language" => "lang"
  }

  @sort_values ~w(relevance newest oldest title)

  @kind_values ~w(all book article image av)a

  @kind_labels %{
    all: "Semua",
    book: "Buku",
    article: "Artikel ilmiah",
    image: "Gambar & karya seni",
    av: "Audio/Video"
  }

  @sort_options [
    {"Paling relevan", "relevance"},
    {"Terbaru", "newest"},
    {"Terlama", "oldest"},
    {"Judul A sampai Z", "title"}
  ]

  @glam_meta %{
    "Library" => %{
      label: "Perpustakaan",
      icon: "hero-book-open",
      badge: "bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/20",
      dot: "bg-blue-500"
    },
    "Museum" => %{
      label: "Museum",
      icon: "hero-building-storefront",
      badge: "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20",
      dot: "bg-amber-500"
    },
    "Archive" => %{
      label: "Arsip",
      icon: "hero-archive-box",
      badge: "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20",
      dot: "bg-emerald-500"
    },
    "Gallery" => %{
      label: "Galeri",
      icon: "hero-photo",
      badge: "bg-pink-500/10 text-pink-600 dark:text-pink-400 border-pink-500/20",
      dot: "bg-pink-500"
    }
  }

  @type_labels %{
    "book" => "Buku",
    "series" => "Seri",
    "movie" => "Film",
    "album" => "Album",
    "course" => "Kursus",
    "other" => "Lainnya"
  }

  @institution_labels %{
    "library" => "Perpustakaan",
    "museum" => "Museum",
    "gallery" => "Galeri",
    "archive" => "Arsip"
  }

  @facet_groups [
    {:units, "Organisasi", "org", true, true},
    {:glam_types, "Sektor GLAM", "sector", true, false},
    {:collection_types, "Jenis koleksi", "type", true, false},
    {:subjects, "Subjek", "subject", true, false},
    {:creators, "Kreator / Penulis", "creator", false, false},
    {:institution_types, "Jenis institusi", "institution_type", false, false},
    {:languages, "Bahasa", "lang", false, false}
  ]

  @muted_cover_hues [10, 35, 145, 178, 215, 335]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Jelajahi Koleksi")
     |> assign(
       :og_description,
       "Jelajahi koleksi digital GLAM Indonesia: buku, benda museum, arsip, dan karya " <>
         "galeri dari berbagai lembaga dan komunitas kurator."
     )
     |> assign(:sort_options, @sort_options)
     |> assign(:kind_values, @kind_values)
     |> assign_new(:org_options, fn -> Public.list_org_filter_options() end)
     |> assign_new(:locations, fn -> Public.list_org_locations() end)
     |> assign(:facets, %{})
     |> assign(:filters, empty_filters())
     |> assign(:page, 1)
     |> assign(:page_size, @grid_page_size)
     |> assign(:view, "grid")
     |> assign(:total, 0)
     |> assign(:total_pages, 1)
     |> assign(:loading, false)
     |> assign(:load_error, false)
     |> assign(:expanded_groups, [])
     |> assign(:eager_ids, MapSet.new())
     # Seed the stream so the first connected render (before handle_async
     # delivers results) has @streams.collections to render.
     |> stream(:collections, [])
     # Federation state (Phase C2): external results are assigned per provider
     # and only populated by an explicit, connected submit (spec D4).
     |> assign(:external, %{})
     |> assign(:external_display, [])
     |> assign(:external_hidden, 0)
     |> assign(:external_notice, nil)
     |> assign(:last_submitted_q, nil)
     |> assign(:last_external_q, nil)
     |> assign(:nav_initialized, false)
     |> assign(:visitor_key, visitor_key(socket))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters = parse_filters(params)
    page = parse_page(params["page"])
    view = parse_view(params, filters)
    ext = parse_ext(params)
    kind = parse_kind(params)
    page_size = if view == "grid", do: @grid_page_size, else: @list_page_size
    opts = to_opts(filters, page, page_size)

    # SEO (spec §6.3): URLs with a query are noindex,follow; browse URLs are
    # indexable. The root layout renders the robots meta from these assigns.
    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:view, view)
      |> assign(:ext, ext)
      |> assign(:kind, kind)
      |> assign(:noindex, filters.q != "")
      |> assign(:robots, "noindex, follow")
      |> assign(:openalex_budget, Budget.status())

    # The page must be fully restorable from the URL: the disconnected (static)
    # render loads synchronously for crawlers and first paint; connected
    # navigations load via start_async so the search header and facets never
    # lose focus or scroll position (spec §6A.6).
    if connected?(socket) do
      {:noreply,
       socket
       |> assign(:loading, true)
       |> assign(:page_size, page_size)
       |> assign(:last_opts, opts)
       |> start_async(:results, fn -> fetch_results(opts, page, page_size) end)}
    else
      {:noreply, fetch_and_assign(socket, opts, page, page_size)}
    end
  end

  @impl true
  def handle_async(:results, {:ok, payload}, socket) do
    %{collections: collections, total: total, page: page, facets: facets} = payload

    socket =
      socket
      |> assign(:loading, false)
      |> assign(:load_error, false)
      |> assign(:total, total)
      |> assign(:page, page)
      |> assign(:total_pages, max(1, ceil(total / socket.assigns.page_size)))
      |> assign(
        :eager_ids,
        collections |> Enum.take(4) |> MapSet.new(& &1.id)
      )

    socket = if facets, do: assign(socket, :facets, facets), else: socket

    {:noreply, stream(socket, :collections, collections, reset: true)}
  end

  def handle_async(:results, {:exit, reason}, socket) do
    Logger.error("collections search failed: #{Exception.format_exit(reason)}")

    {:noreply,
     socket
     |> assign(:loading, false)
     |> assign(:load_error, true)}
  end

  # --- external provider results (Phase C2) ---

  def handle_async({:provider, id}, {:ok, {:ok, page}}, socket) do
    state = %{
      state: page.status,
      results: page.results,
      total: page.total,
      more_url: page.more_url,
      took_ms: page.took_ms,
      stale_age_min: Map.get(page, :stale_age_min)
    }

    {:noreply, socket |> put_external(id, state) |> refresh_external_display()}
  end

  def handle_async({:provider, id}, {:ok, {:error, %{status: :rate_limited} = error}}, socket) do
    retry_after = Map.get(error, :retry_after) || 30

    socket = put_external(socket, id, %{state: :rate_limited, retry_after: retry_after})

    # Re-enable the retry button when the cooldown ends (§8.7.4). No ticking
    # countdown — just a static number and an auto re-enable.
    if retry_after <= 60 do
      Process.send_after(self(), {:cooldown_done, id}, (retry_after + 1) * 1000)
    end

    {:noreply, socket}
  end

  def handle_async({:provider, id}, {:ok, {:error, %{status: :budget} = error}}, socket) do
    socket =
      socket
      |> put_external(id, %{state: :budget, resets_at: Map.get(error, :resets_at)})
      |> assign(:openalex_budget, Budget.status())
      |> refresh_external_display()

    {:noreply, socket}
  end

  def handle_async({:provider, id}, {:ok, {:error, %{status: status}}}, socket) do
    {:noreply, socket |> put_external(id, %{state: status}) |> refresh_external_display()}
  end

  def handle_async({:provider, id}, {:exit, reason}, socket) do
    Logger.warning("external provider #{id} failed: #{inspect(reason)}")
    {:noreply, socket |> put_external(id, %{state: :error}) |> refresh_external_display()}
  end

  @impl true
  def handle_info({:cooldown_done, id}, socket) do
    case Map.get(socket.assigns.external, id) do
      %{state: :rate_limited} ->
        {:noreply, put_external(socket, id, %{state: :rate_limited, retry_after: nil})}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  # --- events ---

  @impl true
  def handle_event("search", %{"value" => value}, socket) do
    apply_filters(socket, %{q: value}, page: 1)
  end

  # Local submit only (Enter / "Cari"). External sources are searched from
  # the explicit "Cari dari sumber lain" button below the results (D4).
  def handle_event("submit_search", %{"q" => q}, socket) do
    apply_filters(socket, %{q: q}, page: 1)
  end

  # The one and only external fan-out trigger (spec D4, §8.1): an explicit
  # click after the local results are on screen.
  def handle_event("search_external", _params, socket) do
    {:noreply, maybe_fan_out(socket, socket.assigns.filters.q, force: true)}
  end

  def handle_event("clear_search", _params, socket) do
    apply_filters(socket, %{q: ""}, page: 1)
  end

  # Checkbox semantics: clicking the active value clears it (spec §6A.6).
  def handle_event("filter", %{"field" => field, "val" => value}, socket) do
    key = Map.fetch!(@param_to_filter, field)
    value = if value == "", do: nil, else: value
    value = if facet_active?(socket.assigns.filters, key, value), do: nil, else: value

    apply_filters(socket, %{key => value}, page: 1)
  end

  def handle_event("select_filter", params, socket) do
    field = Map.fetch!(params, "field")
    key = Map.fetch!(@param_to_filter, field)
    raw = Map.get(params, field)
    value = if raw in [nil, ""], do: nil, else: raw

    apply_filters(socket, %{key => value}, page: 1)
  end

  def handle_event("change_sort", %{"sort" => sort}, socket) do
    sort = if sort in @sort_values, do: sort, else: nil
    apply_filters(socket, %{}, sort: sort)
  end

  def handle_event("set_view", %{"view" => view}, socket) when view in ~w(grid list) do
    apply_filters(socket, %{}, view: view)
  end

  def handle_event("set_kind", %{"kind" => kind}, socket) when is_binary(kind) do
    kind_atom = parse_kind(%{"kind" => kind})

    # A different kind means different sources: drop the previous external
    # results and offer the explicit search again for the new kind.
    socket =
      socket
      |> assign(:external, %{})
      |> assign(:external_display, [])
      |> assign(:external_notice, nil)
      |> assign(:last_external_q, nil)

    apply_filters(socket, %{}, kind: kind_atom)
  end

  def handle_event("retry_provider", %{"provider" => provider_id}, socket) do
    id = Enum.find(provider_ids(), &(to_string(&1) == provider_id))
    provider = id && Router.provider(id)

    if connected?(socket) && provider do
      query =
        external_query(
          socket.assigns.filters.q,
          socket.assigns.kind,
          external_languages(socket.assigns.filters.language)
        )

      socket =
        socket
        |> cancel_provider_async(id)
        |> put_external(id, %{state: :loading})
        |> start_async({:provider, id}, fn ->
          Federator.run(provider, query, bypass_cache: true)
        end)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("clear", _params, socket) do
    # Full reset: filters, q, page, and back to the default view.
    {:noreply, push_patch(socket, to: ~p"/collections")}
  end

  def handle_event("clear_filter", %{"field" => field}, socket) do
    key = Map.fetch!(@param_to_filter, field)
    apply_filters(socket, %{key => nil}, page: 1)
  end

  def handle_event("open_filters", _params, socket) do
    {:noreply, push_event(socket, "open-filter-drawer", %{})}
  end

  def handle_event("close_filters", _params, socket) do
    {:noreply, push_event(socket, "close-filter-drawer", %{})}
  end

  def handle_event("expand_group", %{"group" => group}, socket) do
    # Group ids come from phx-value (strings); match against the known atoms
    # instead of creating new ones from user input.
    group = Enum.find(@facet_groups, &(to_string(elem(&1, 0)) == group))

    if group do
      group = elem(group, 0)

      expanded =
        if group in socket.assigns.expanded_groups,
          do: List.delete(socket.assigns.expanded_groups, group),
          else: [group | socket.assigns.expanded_groups]

      {:noreply, assign(socket, :expanded_groups, expanded)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("retry", _params, socket) do
    opts = socket.assigns[:last_opts]

    if connected?(socket) && opts do
      page = socket.assigns.page
      page_size = socket.assigns.page_size

      {:noreply,
       socket
       |> assign(:loading, true)
       |> assign(:load_error, false)
       |> start_async(:results, fn -> fetch_results(opts, page, page_size) end)}
    else
      {:noreply, socket}
    end
  end

  def handle_event(_other, _params, socket), do: {:noreply, socket}

  # --- federation (Phase C2) ---

  # Per-visitor external-search limiter (§8.3.3): max 10/minute per session+IP.
  @visitor_limit 10
  @visitor_window 60

  # External fan-out trigger rules (spec D4, §8.1) — all must hold: socket
  # connected, human-submitted, `q` >= 3 chars, `ext=1`, not visitor-limited.
  defp maybe_fan_out(socket, q, opts) do
    force? = Keyword.get(opts, :force, false)
    trimmed = String.trim(q)
    kind = Keyword.get(opts, :kind, socket.assigns.kind)
    provider_ids = Enum.map(Router.providers_for(kind), & &1.id())

    cond do
      not connected?(socket) ->
        socket

      String.length(trimmed) < 3 ->
        socket

      socket.assigns.ext != "1" ->
        socket

      not force? and socket.assigns.last_external_q == {trimmed, kind} ->
        # Same query already fanned out (e.g. facet change after a submit).
        socket

      provider_ids == [] ->
        assign(socket, :external_notice, :no_providers)

      RateLimiter.check(:ext_search, socket.assigns.visitor_key, @visitor_limit, @visitor_window) !=
          :ok ->
        assign(socket, :external_notice, :visitor_limited)

      true ->
        query =
          external_query(trimmed, kind, external_languages(socket.assigns.filters.language))

        socket
        |> assign(:external_notice, nil)
        |> assign(:last_external_q, {trimmed, kind})
        |> fan_out(query, provider_ids)
    end
  end

  defp fan_out(socket, query, provider_ids) do
    # Drop any in-flight provider tasks from the previous query (§8.2).
    socket =
      Enum.reduce(provider_ids, socket, fn id, acc -> cancel_provider_async(acc, id) end)

    external = Map.new(provider_ids, fn id -> {id, %{state: :loading}} end)

    # Seed the display with loading blocks so skeletons (with reserved height)
    # render immediately instead of an empty gap.
    loading_display =
      Enum.map(provider_ids, fn id ->
        %{
          id: id,
          label: Router.provider_label(id),
          state: :loading,
          results: [],
          total: nil,
          more_url: nil,
          more_from_url: nil
        }
      end)

    socket
    |> assign(:external, external)
    |> assign(:external_display, loading_display)
    |> then(fn socket ->
      Enum.reduce(provider_ids, socket, fn id, acc ->
        provider = Router.provider(id)
        start_async(acc, {:provider, id}, fn -> Federator.run(provider, query) end)
      end)
    end)
  end

  # Local language facet values are free text ("Indonesia", "ind", "en", …).
  # Map them to ISO 639-1 for the providers, as a boost unless the user
  # explicitly picked a language (§8.6).
  @iso_languages %{
    "indonesia" => "id",
    "indonesian" => "id",
    "ind" => "id",
    "id" => "id",
    "inggris" => "en",
    "english" => "en",
    "en" => "en",
    "arab" => "ar",
    "ar" => "ar",
    "jawa" => "jv",
    "jv" => "jv",
    "sunda" => "su",
    "su" => "su",
    "hebrew" => "he",
    "he" => "he",
    "heb" => "he"
  }

  defp external_languages(nil), do: []

  defp external_languages(value) when is_binary(value) do
    case Map.get(@iso_languages, value |> String.trim() |> String.downcase()) do
      nil -> []
      iso -> [iso]
    end
  end

  defp external_languages(_), do: []

  defp external_query(text, kind, languages) do
    Query.new(text, kind: kind, per_page: 8, languages: languages)
  end

  defp cancel_provider_async(socket, id), do: cancel_async(socket, {:provider, id})

  defp provider_ids do
    @kind_values
    |> Enum.flat_map(&Enum.map(Router.providers_for(&1), fn p -> p.id() end))
    |> Enum.uniq()
  end

  defp put_external(socket, id, state) do
    assign(socket, :external, Map.put(socket.assigns.external, id, state))
  end

  # Builds the display list: per-provider groups in router order, deduped
  # across sources (§8.4). Empty/error blocks stay visible with their status.
  defp refresh_external_display(socket) do
    external = socket.assigns.external
    ordered_ids = Router.providers_for(socket.assigns.kind) |> Enum.map(& &1.id())

    ok_results =
      external
      |> Enum.filter(fn {_id, v} -> Map.get(v, :state) in [:ok, :cache_hit, :stale] end)
      |> Map.new(fn {id, v} -> {id, v.results} end)

    {deduped, hidden} = Dedupe.run(ok_results)
    by_source = Enum.group_by(deduped, & &1.source)

    all_view? = socket.assigns.kind == :all

    display =
      Enum.map(ordered_ids, fn id ->
        provider = Router.provider(id)
        block = Map.get(external, id, %{state: :loading})
        results = Map.get(by_source, id, [])

        # In the `all` view show the top 3 per provider (§8.5) with a link to
        # the provider's own kind tab for more.
        {shown, truncated?} =
          if all_view? and length(results) > 3,
            do: {Enum.take(results, 3), true},
            else: {results, false}

        block
        |> Map.put(:id, id)
        |> Map.put(:label, provider && provider.label())
        |> Map.put(
          :results,
          if(Map.get(block, :state) in [:ok, :cache_hit, :stale], do: shown, else: [])
        )
        |> Map.put(
          :more_url,
          Map.get(block, :more_url) ||
            (provider && more_url_for(provider, socket.assigns.filters.q))
        )
        |> Map.put(
          :more_from_url,
          truncated? &&
            path_for(
              socket.assigns.filters,
              socket.assigns.view,
              1,
              socket.assigns.ext,
              Router.display_kind(id)
            )
        )
      end)

    limited_count =
      Enum.count(display, &(Map.get(&1, :state) in [:rate_limited, :budget]))

    notice =
      cond do
        socket.assigns.external_notice == :visitor_limited -> :visitor_limited
        limited_count >= 2 -> {:summary, limited_count, length(display)}
        true -> nil
      end

    socket
    |> assign(:external_display, display)
    |> assign(:external_notice, notice)
    |> assign(:external_hidden, hidden)
    |> assign(:openalex_budget, Budget.status())
  end

  defp more_url_for(provider, text) do
    if function_exported?(provider, :more_url, 1), do: provider.more_url(text), else: nil
  end

  # Session+IP key for the visitor limiter (no identifiers sent upstream).
  defp visitor_key(socket) do
    peer =
      case get_connect_info(socket, :peer_data) do
        %{address: address} -> :inet.ntoa(address) |> to_string()
        _ -> "unknown"
      end

    "#{socket.id || "no-session"}:#{peer}"
  end

  # --- data loading ---

  defp fetch_results(opts, page, page_size) do
    total = Public.count_search_collections(opts)
    total_pages = max(1, ceil(total / page_size))
    # Out-of-range pages clamp to the last page, never error (spec §6.1).
    clamped = min(page, total_pages)

    collections =
      if total == 0,
        do: [],
        else: opts |> Keyword.put(:page, clamped) |> Public.search_collections()

    # Facets only on page 1 (equivalent of the API contract's `facets=none`
    # when only the page changed); callers keep the previous facets otherwise.
    facets = if page == 1, do: Public.collection_search_facets(opts), else: nil

    # NOTE: do not return {:ok, ...} — LiveView's handle_async already wraps
    # the task result as {:ok, result}; a second {:ok, ...} would nest it.
    %{collections: collections, total: total, page: clamped, facets: facets}
  end

  defp fetch_and_assign(socket, opts, page, page_size) do
    payload = fetch_results(opts, page, page_size)

    %{collections: collections, total: total, page: page, facets: facets} = payload

    socket
    |> assign(:total, total)
    |> assign(:page, page)
    |> assign(:total_pages, max(1, ceil(total / page_size)))
    |> assign(:loading, false)
    |> assign(:eager_ids, collections |> Enum.take(4) |> MapSet.new(& &1.id))
    |> then(fn socket ->
      if facets, do: assign(socket, :facets, facets), else: socket
    end)
    |> then(fn socket -> stream(socket, :collections, collections, reset: true) end)
  rescue
    error ->
      Logger.error("collections search failed during static render: #{Exception.message(error)}")

      socket
      |> assign(:loading, false)
      |> assign(:load_error, true)
      |> assign(:total, 0)
      |> assign(:total_pages, 1)
  end

  # --- URL building ---

  # Single navigation entry point: merge filter overrides, then patch the URL.
  defp apply_filters(socket, filter_overrides, extra_overrides) do
    extra = Map.new(extra_overrides)

    filters =
      Enum.reduce(filter_overrides, socket.assigns.filters, fn {key, value}, acc ->
        Map.put(acc, key, value)
      end)

    view = Map.get(extra, :view, socket.assigns.view)
    page = Map.get(extra, :page, socket.assigns.page)
    sort = Map.get(extra, :sort, socket.assigns.filters.sort)
    ext = Map.get(extra, :ext, socket.assigns[:ext] || "1")
    kind = Map.get(extra, :kind, socket.assigns[:kind] || :all)

    filters = Map.put(filters, :sort, sort)

    {:noreply, push_patch(socket, to: path_for(filters, view, page, ext, kind))}
  end

  defp path_for(filters, view, page, ext, kind) do
    query = query_map(filters, view, page, ext, kind)
    ~p"/collections?#{query}"
  end

  # Whitelisted params only, defaults omitted (spec §6.1: "Unknown params are
  # ignored"; §6A.6: URL is the state).
  defp query_map(filters, view, page, ext, kind) do
    q = filters[:q] || ""

    base =
      @filter_to_param
      |> Enum.reduce(%{}, fn {key, param}, acc ->
        case Map.get(filters, key) do
          nil -> acc
          "" -> acc
          value -> Map.put(acc, param, value)
        end
      end)

    base =
      case Map.get(filters, :sort) do
        # Drop the sort param when it equals the effective default:
        # relevance with a query, newest without one (spec §6.1).
        sort when sort in [nil, "", "relevance", "newest"] ->
          default_sort = if q == "", do: "newest", else: "relevance"

          if sort in [nil, ""] or sort == default_sort,
            do: base,
            else: Map.put(base, "sort", sort)

        sort ->
          Map.put(base, "sort", sort)
      end

    base = if page > 1, do: Map.put(base, "page", page), else: base
    base = if view == default_view(q), do: base, else: Map.put(base, "view", view)

    # ext/kind: defaults omitted (ext=1, kind=all) per the §6.1 contract.
    base = if ext == "1", do: base, else: Map.put(base, "ext", "0")
    base = if kind == :all, do: base, else: Map.put(base, "kind", to_string(kind))

    base
  end

  # Default view: grid while browsing (no `q`), list while searching (§6.1).
  defp default_view(q), do: if(q == "", do: "grid", else: "list")

  defp page_path(filters, view, ext, kind, page), do: path_for(filters, view, page, ext, kind)

  # --- parsing ---

  defp empty_filters,
    do: %{
      q: "",
      glam_type: nil,
      node_id: nil,
      type: nil,
      institution_type: nil,
      city: nil,
      province: nil,
      language: nil,
      subject: nil,
      creator: nil,
      has_ebook: nil,
      sort: nil
    }

  defp parse_filters(params) do
    params = normalize_legacy_params(params)

    %{
      q:
        params
        |> Map.get("q", "")
        |> to_string()
        |> String.trim()
        |> String.slice(0, @max_q_length),
      glam_type: empty_to_nil(params["sector"]),
      node_id: empty_to_nil(params["org"]),
      type: empty_to_nil(params["type"]),
      institution_type: empty_to_nil(params["institution_type"]),
      city: empty_to_nil(params["city"]),
      province: empty_to_nil(params["prov"]),
      language: empty_to_nil(params["lang"]),
      subject: empty_to_nil(params["subject"]),
      creator: empty_to_nil(params["creator"]),
      has_ebook: parse_has_ebook(params["has_ebook"]),
      sort: parse_sort(params["sort"])
    }
  end

  # Old links keep working: a legacy name is used only when the new name is
  # absent (§6.1).
  defp normalize_legacy_params(params) do
    Enum.reduce(@legacy_params, params, fn {legacy, new}, acc ->
      cond do
        Map.has_key?(acc, new) and acc[new] not in [nil, ""] -> acc
        is_nil(acc[legacy]) or acc[legacy] == "" -> acc
        true -> Map.put(acc, new, acc[legacy])
      end
    end)
  end

  # Only "true" and "false" are valid states; anything else means no filter.
  defp parse_has_ebook(v) when v in ["true", "false"], do: v
  defp parse_has_ebook(_), do: nil

  defp parse_sort(nil), do: nil
  defp parse_sort(sort) when sort in @sort_values, do: sort
  defp parse_sort(_), do: nil

  defp parse_page(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, ""} when n >= 1 -> n
      _ -> 1
    end
  end

  defp parse_page(_), do: 1

  defp parse_view(params, filters) do
    case params["view"] do
      "grid" -> "grid"
      "list" -> "list"
      _ -> default_view(filters.q)
    end
  end

  # ext defaults to on (spec §6.1); only "0" turns it off.
  defp parse_ext(params) do
    if params["ext"] == "0", do: "0", else: "1"
  end

  defp parse_kind(params) do
    case params["kind"] do
      kind when kind in ~w(all book article image av) -> String.to_existing_atom(kind)
      _ -> :all
    end
  end

  defp kind_label(kind), do: Map.fetch!(@kind_labels, kind)

  defp empty_to_nil(nil), do: nil
  defp empty_to_nil(""), do: nil
  defp empty_to_nil(value), do: String.trim(value)

  defp to_opts(filters, page, page_size) do
    page_size = min(page_size, @max_page_size)

    [
      search: filters.q,
      glam_type: filters.glam_type,
      node_id: to_int(filters.node_id),
      collection_type: filters.type,
      has_ebook: filters.has_ebook,
      institution_type: filters.institution_type,
      city: filters.city,
      province: filters.province,
      subject: filters.subject,
      language: filters.language,
      creator: filters.creator,
      sort: filters.sort,
      page: page,
      page_size: page_size
    ]
  end

  defp to_int(nil), do: nil

  defp to_int(value) when is_integer(value), do: value

  defp to_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {n, ""} -> n
      _ -> nil
    end
  end

  # --- labels / formatting ---

  defp glam_label(nil), do: nil
  defp glam_label(glam_type), do: get_in(@glam_meta, [glam_type, :label]) || glam_type

  defp glam_dot(value), do: get_in(@glam_meta, [value, :dot]) || "bg-base-content/30"

  defp institution_label(nil), do: nil

  defp institution_label(institution_type),
    do: Map.get(@institution_labels, institution_type, institution_type)

  defp type_label(value), do: Map.get(@type_labels, value, value)

  defp ebook_chip_label("true"), do: "Punya e-book"
  defp ebook_chip_label("false"), do: "Koleksi fisik saja"
  defp ebook_chip_label(_), do: nil

  defp facet_active?(filters, field, value) do
    to_string(Map.get(filters, field)) == to_string(value)
  end

  # Counts are formatted id-ID: `1.043` (spec §5 — the old `2rb` is banned).
  defp format_count(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.replace(~r/(\d)(?=(\d{3})+$)/, "\\1.")
  end

  defp format_count(_), do: ""

  defp result_count_label(total, q) when q != "",
    do: "#{format_count(total)} hasil untuk “#{q}”"

  defp result_count_label(total, _q), do: "#{format_count(total)} koleksi"

  defp org_name_for(assigns, node_id) when not is_nil(node_id) do
    id = to_int(node_id)

    unit =
      Enum.find(assigns.facets[:units] || [], &(&1.value == id)) ||
        Enum.find(assigns.org_options, &(&1.node_id == id))

    cond do
      is_map(unit) and Map.has_key?(unit, :label) -> unit.label
      is_map(unit) and Map.has_key?(unit, :name) -> unit.name
      true -> "Organisasi"
    end
  end

  defp org_name_for(_assigns, _node_id), do: nil

  defp any_filters?(filters) do
    filter_count(filters) > 0
  end

  defp filter_count(filters) do
    base =
      Enum.count(
        [
          :glam_type,
          :node_id,
          :type,
          :institution_type,
          :city,
          :province,
          :language,
          :subject,
          :creator
        ],
        fn key -> Map.get(filters, key) not in [nil, ""] end
      )

    base + if(filters.has_ebook in [nil, ""], do: 0, else: 1)
  end

  # Deterministic cover hue per record id (§6A.5.8) — muted palette.
  defp cover_hue(id) do
    Enum.at(@muted_cover_hues, rem(:erlang.phash2(id), length(@muted_cover_hues)))
  end

  defp facet_group_hidden?(values, selected_value) do
    length(values) < 2 and is_nil(selected_value)
  end

  defp visible_values(values, group, expanded_groups) do
    if group in expanded_groups, do: values, else: Enum.take(values, @facet_top_n)
  end

  defp facet_values(facets, group) when is_map(facets), do: facets[group] || []
  defp facet_values(_facets, _group), do: []

  defp selected_filter(filters, group_key) do
    filter_key =
      case group_key do
        :units -> :node_id
        :collection_types -> :type
        :institution_types -> :institution_type
        :glam_types -> :glam_type
        :languages -> :language
        :subjects -> :subject
        :creators -> :creator
      end

    Map.get(filters, filter_key)
  end

  # --- render ---

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:active, active_filters(assigns))
      |> assign(:external_visible, external_visible?(assigns))
      |> assign(:external_offer, external_offer?(assigns))

    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <a
        href="#hasil"
        class="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-lg focus:bg-primary focus:px-4 focus:py-2 focus:font-medium focus:text-primary-content"
      >
        Lewati ke hasil pencarian
      </a>

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-8 pb-12">
        <h1 class="text-3xl sm:text-4xl font-semibold mb-6">Jelajahi koleksi</h1>

        <%!-- Search header (§6A.5.1) --%>
        <form id="collections-search-form" role="search" phx-submit="submit_search" class="flex gap-2">
          <div class="relative flex-1 min-w-0">
            <label for="collections-q" class="sr-only">Cari koleksi</label>
            <.icon
              name="hero-magnifying-glass"
              class="absolute left-4 top-1/2 -translate-y-1/2 size-5 text-base-content/40 pointer-events-none"
            />
            <input
              id="collections-q"
              type="search"
              name="q"
              value={@filters.q}
              placeholder="Cari judul, pengarang, subjek, atau ISBN"
              autocomplete="off"
              class="input input-bordered w-full h-12 pl-12 pr-10 text-base bg-base-100"
              phx-keyup="search"
              phx-debounce="300"
              phx-hook="SearchInput"
            />
          </div>
          <button type="submit" class="btn btn-primary h-12 min-h-12 px-6">Cari</button>
        </form>

        <%!-- Kind tabs (§8.5): drives provider routing for external sources --%>
        <nav
          class="-mx-4 px-4 sm:mx-0 sm:px-0 flex gap-2 overflow-x-auto mt-4 pb-1"
          aria-label="Jenis hasil"
        >
          <.link
            :for={kind <- @kind_values}
            patch={path_for(@filters, @view, 1, @ext, kind)}
            aria-current={if(@kind == kind, do: "page", else: nil)}
            class={[
              "btn btn-sm shrink-0",
              @kind == kind && "btn-primary",
              @kind != kind && "btn-ghost border border-base-300 bg-base-100"
            ]}
          >
            {kind_label(kind)}
          </.link>
        </nav>

        <%!-- Active filter chips (§6A.5.3) --%>
        <div
          id="active-chips"
          class="flex flex-wrap items-center gap-2 mt-4"
          aria-label="Filter aktif"
        >
          <.link
            :for={chip <- @active}
            id={"active-chip-#{chip.field}"}
            patch={path_for(chip.filters_after_clear, @view, 1, @ext, @kind)}
            aria-label={"Hapus filter #{chip.label}"}
            class="inline-flex items-center gap-1.5 rounded-full bg-primary/10 text-primary pl-3 pr-2 py-1.5 text-sm font-medium hover:bg-primary/20 transition-colors"
          >
            {chip.label}
            <.icon name="hero-x-mark" class="size-3.5" />
          </.link>

          <button
            :if={any_filters?(@filters) or @filters.q != ""}
            phx-click="clear"
            class="text-sm text-base-content/50 hover:text-error underline underline-offset-2 transition-colors"
          >
            Hapus semua filter
          </button>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-[280px_minmax(0,1fr)] gap-8 items-start mt-6">
          <%!-- Facet sidebar (desktop) --%>
          <aside id="filters-sidebar" class="hidden lg:block lg:sticky lg:top-24" aria-label="Filter">
            <.facet_panel
              filters={@filters}
              facets={@facets}
              locations={@locations}
              expanded_groups={@expanded_groups}
              dialog={false}
              dom_id="sidebar"
            />
          </aside>

          <%!-- Results --%>
          <section
            id="hasil"
            aria-label="Hasil"
            tabindex="-1"
            phx-hook="ResultsScroller"
            data-page={@page}
            data-q={@filters.q}
            class="min-w-0 focus:outline-none"
          >
            <%!-- Toolbar (§6A.5.5) --%>
            <div id="results-toolbar" class="flex flex-wrap items-center gap-3">
              <p id="results-count" role="status" aria-live="polite" class="font-semibold m-0 mr-auto">
                {result_count_label(@total, @filters.q)}
              </p>

              <button
                type="button"
                phx-click="open_filters"
                class="btn btn-outline btn-sm lg:hidden"
                aria-haspopup="dialog"
              >
                <.icon name="hero-funnel" class="size-4" /> Filter
                <span
                  :if={filter_count(@filters) > 0}
                  class="badge badge-primary badge-sm rounded-full"
                >
                  {filter_count(@filters)}
                </span>
              </button>

              <select
                id="sort-select"
                aria-label="Urutkan"
                class="select select-bordered select-sm"
                phx-change="change_sort"
              >
                <.option
                  :for={{label, value} <- @sort_options}
                  value={value}
                  selected={effective_sort(@filters) == value}
                >
                  {label}
                </.option>
              </select>

              <div
                id="view-toggle"
                role="group"
                aria-label="Tampilan"
                class="join border border-base-300 rounded-lg overflow-hidden"
              >
                <button
                  type="button"
                  phx-click="set_view"
                  phx-value-view="grid"
                  aria-pressed={if(@view == "grid", do: "true", else: "false")}
                  aria-label="Tampilan kisi"
                  class={[
                    "btn btn-ghost btn-sm join-item rounded-none",
                    @view == "grid" && "bg-primary/10 text-primary"
                  ]}
                >
                  <.icon name="hero-squares-2x2" class="size-4" />
                </button>
                <button
                  type="button"
                  phx-click="set_view"
                  phx-value-view="list"
                  aria-pressed={if(@view == "list", do: "true", else: "false")}
                  aria-label="Tampilan daftar"
                  class={[
                    "btn btn-ghost btn-sm join-item rounded-none",
                    @view == "list" && "bg-primary/10 text-primary"
                  ]}
                >
                  <.icon name="hero-bars-3" class="size-4" />
                </button>
              </div>
            </div>

            <%!-- External results promoted above local ones when local is empty (§6A.7) --%>
            <CollectionsExternal.section
              :if={@external_visible and !@loading and !@load_error and @total == 0}
              blocks={@external_display}
              notice={@external_notice}
              promoted={true}
              hidden_count={@external_hidden}
              openalex_budget={@openalex_budget}
              article_url={path_for(@filters, @view, 1, @ext, :article)}
            />

            <%!-- Error state (§6A.8) --%>
            <div
              :if={@load_error}
              role="alert"
              class="mt-6 rounded-xl border border-error/30 bg-error/5 p-6 text-center"
            >
              <p class="font-medium">Koleksi Curatorian sementara tidak dapat dimuat.</p>
              <button phx-click="retry" class="btn btn-primary btn-sm mt-3" disabled={@loading}>
                Coba lagi
              </button>
            </div>

            <%!-- Loading skeletons (§6A.5.12) — shaped like the active view --%>
            <div :if={@loading} class="mt-6" aria-hidden="true">
              <div
                :if={@view == "grid"}
                class="grid gap-5 grid-cols-1 sm:grid-cols-2 xl:grid-cols-3"
              >
                <div :for={_i <- 1..6} class="rounded-2xl border border-base-300/70 overflow-hidden">
                  <div class="skeleton aspect-[3/4] rounded-none"></div>
                  <div class="p-4 space-y-2">
                    <div class="skeleton h-4 w-2/3"></div>
                    <div class="skeleton h-3 w-full"></div>
                    <div class="skeleton h-9 w-full mt-2"></div>
                  </div>
                </div>
              </div>
              <div :if={@view == "list"} class="space-y-4">
                <div :for={_i <- 1..3} class="flex gap-4 items-start">
                  <div class="skeleton w-[72px] sm:w-24 aspect-[3/4] rounded"></div>
                  <div class="flex-1 space-y-2 py-1">
                    <div class="skeleton h-5 w-2/3"></div>
                    <div class="skeleton h-3 w-1/2"></div>
                    <div class="skeleton h-3 w-full"></div>
                  </div>
                </div>
              </div>
            </div>

            <%!-- Empty state (§6A.8) --%>
            <div
              :if={!@loading and !@load_error and @total == 0}
              class="mt-6 rounded-2xl border border-dashed border-base-300 bg-base-100 p-12 text-center"
            >
              <div class="mx-auto mb-4 flex size-14 items-center justify-center rounded-2xl bg-base-200">
                <.icon name="hero-magnifying-glass" class="size-7 text-base-content/40" />
              </div>
              <h3 class="text-base font-semibold">
                {empty_state_title(@filters.q)}
              </h3>
              <p class="mt-1 text-sm text-base-content/60">
                Coba kata kunci yang lebih umum, periksa ejaan, atau hapus filter.
              </p>
              <button phx-click="clear" class="btn btn-primary btn-sm mt-4">
                Hapus semua filter
              </button>
            </div>

            <%!-- Results stream: rich cards (grid) or rows (list) --%>
            <div
              id="collections"
              phx-update="stream"
              class={[
                "mt-6",
                @view == "grid" && "grid gap-5 grid-cols-1 sm:grid-cols-2 xl:grid-cols-3",
                @view == "list" && "flex flex-col",
                (@loading or @total == 0) && "hidden"
              ]}
            >
              <div :for={{id, col} <- @streams.collections} id={id}>
                <%= if @view == "grid" do %>
                  <.collection_card col={col} eager={col.id in @eager_ids} />
                <% else %>
                  <.collection_row col={col} eager={col.id in @eager_ids} />
                <% end %>
              </div>
            </div>

            <Pagination.pagination
              :if={!@loading and @total_pages > 1}
              current={@page}
              total_pages={@total_pages}
              path={fn p -> page_path(@filters, @view, @ext, @kind, p) end}
              class="mt-10"
            />

            <%!-- Explicit external search (spec D4): nothing is sent to
                 third-party sources until this button is pressed. --%>
            <div :if={@external_offer} id="external-search-invite" class="mt-8">
              <button
                type="button"
                id="external-search-button"
                phx-click="search_external"
                class="btn btn-outline gap-2"
              >
                <.icon name="hero-globe-alt" class="size-4" /> Cari dari sumber lain
              </button>

              <p :if={@external_notice == :visitor_limited} class="mt-2 text-sm" role="status">
                Anda mencari terlalu cepat. Coba lagi sebentar lagi.
              </p>

              <p :if={@external_notice == :no_providers} class="mt-2 text-sm text-base-content/60">
                Sumber luar untuk jenis hasil ini belum tersedia.
              </p>

              <p class="mt-2 text-xs text-base-content/50">
                Kata kunci pencarian Anda akan dikirim ke layanan pihak ketiga yang dipilih.
                <.link
                  navigate={~p"/privacy-policy"}
                  class="underline underline-offset-2 hover:text-primary"
                >
                  Kebijakan privasi
                </.link>
              </p>
            </div>

            <%!-- External results below local ones otherwise (§6A.7) --%>
            <CollectionsExternal.section
              :if={@external_visible and (@loading or @load_error or @total > 0)}
              blocks={@external_display}
              notice={@external_notice}
              promoted={false}
              hidden_count={@external_hidden}
              openalex_budget={@openalex_budget}
              article_url={path_for(@filters, @view, 1, @ext, :article)}
            />
          </section>
        </div>
      </div>

      <%!-- Mobile filter drawer (§6A.5.4, native dialog for focus trap) --%>
      <dialog id="filter-drawer" class="modal modal-bottom sm:modal-middle" phx-hook="FilterDrawer">
        <div class="modal-box max-h-[85vh]">
          <div class="flex items-center justify-between pb-2">
            <h2 class="text-lg font-bold m-0">Filter</h2>
            <form method="dialog">
              <button class="btn btn-ghost btn-sm btn-circle" aria-label="Tutup">
                <.icon name="hero-x-mark" class="size-5" />
              </button>
            </form>
          </div>
          <.facet_panel
            filters={@filters}
            facets={@facets}
            locations={@locations}
            expanded_groups={@expanded_groups}
            dialog={true}
            dom_id="drawer"
          />
          <button phx-click="close_filters" class="btn btn-primary w-full mt-4">
            Tampilkan {format_count(@total)} hasil
          </button>
        </div>
        <form method="dialog" class="modal-backdrop">
          <button aria-label="Tutup filter" class="sr-only">Tutup</button>
        </form>
      </dialog>
    </Layouts.app>
    """
  end

  defp effective_sort(filters) do
    case filters.sort do
      nil -> if(filters.q == "", do: "newest", else: "relevance")
      sort -> sort
    end
  end

  defp empty_state_title(q) when q != "", do: "Tidak ada koleksi untuk “#{q}”"
  defp empty_state_title(_q), do: "Tidak ada koleksi ditemukan"

  # The external shelf is shown only for the query/kind it was searched for.
  defp external_visible?(assigns) do
    assigns.filters.q != "" and assigns.ext == "1" and external_current?(assigns) and
      assigns.external_display != []
  end

  # Invite to run the external search: an explicit, human-initiated action
  # (spec D4). Hidden once the current query/kind has been searched.
  defp external_offer?(assigns) do
    q = String.trim(assigns.filters.q)

    q != "" and String.length(q) >= 3 and assigns.ext == "1" and
      not external_current?(assigns)
  end

  defp external_current?(assigns) do
    assigns[:last_external_q] == {String.trim(assigns.filters.q), assigns.kind}
  end

  defp active_filters(assigns) do
    filters = assigns.filters
    org_name = org_name_for(assigns, filters.node_id)

    [
      %{field: "sector", value: filters.glam_type, label: glam_label(filters.glam_type)},
      %{
        field: "institution_type",
        value: filters.institution_type,
        label: institution_label(filters.institution_type)
      },
      %{field: "type", value: filters.type, label: type_label(filters.type)},
      %{field: "has_ebook", value: filters.has_ebook, label: ebook_chip_label(filters.has_ebook)},
      %{field: "org", value: filters.node_id, label: org_name},
      %{field: "prov", value: filters.province, label: filters.province},
      %{field: "city", value: filters.city, label: filters.city},
      %{field: "subject", value: filters.subject, label: filters.subject},
      %{field: "lang", value: filters.language, label: filters.language},
      %{field: "creator", value: filters.creator, label: filters.creator}
    ]
    |> Enum.reject(&is_nil(&1.value))
    |> Enum.map(fn chip ->
      %{
        field: chip.field,
        label: chip.label,
        filters_after_clear: Map.put(filters, filter_key(chip.field), nil)
      }
    end)
  end

  defp filter_key(field), do: Map.fetch!(@param_to_filter, field)

  # --- components ---

  attr :filters, :map, required: true
  attr :facets, :map, required: true
  attr :locations, :map, required: true
  attr :expanded_groups, :list, required: true
  attr :dialog, :boolean, default: false
  attr :dom_id, :string, required: true, doc: "unique suffix so ids stay unique across panels"

  defp facet_panel(assigns) do
    assigns = assign(assigns, :groups, @facet_groups)

    ~H"""
    <div class="space-y-1 divide-y divide-base-200">
      <.facet_group
        :for={{group, title, field, open, searchable} <- @groups}
        group={group}
        title={title}
        field={field}
        default_open={open}
        searchable={searchable}
        values={visible_values(facet_values(@facets, group), group, @expanded_groups)}
        all_values={facet_values(@facets, group)}
        filters={@filters}
        expanded={group in @expanded_groups}
        dialog={@dialog}
        dom_id={@dom_id}
      />

      <%!-- Location selects (data hygiene: raw node_profile values, spec §5) --%>
      <details class="group/py py-3" open={false}>
        <summary class="flex cursor-pointer list-none items-center justify-between py-1 font-semibold">
          Lokasi
          <.icon
            name="hero-chevron-down"
            class="size-4 text-base-content/40 group-open:rotate-180 transition-transform"
          />
        </summary>
        <div class="space-y-2 pb-2 pt-2">
          <select
            aria-label="Provinsi"
            class="select select-bordered select-sm w-full"
            phx-change="select_filter"
            phx-value-field="prov"
          >
            <option value="">Semua provinsi</option>
            <.option
              :for={loc <- @locations[:provinces] || []}
              value={loc.value}
              selected={to_string(@filters.province) == to_string(loc.value)}
            >
              {String.trim(loc.value)} ({format_count(loc.count)})
            </.option>
          </select>

          <select
            aria-label="Kota"
            class="select select-bordered select-sm w-full"
            phx-change="select_filter"
            phx-value-field="city"
          >
            <option value="">Semua kota</option>
            <.option
              :for={loc <- @locations[:cities] || []}
              value={loc.value}
              selected={to_string(@filters.city) == to_string(loc.value)}
            >
              {String.trim(loc.value)} ({format_count(loc.count)})
            </.option>
          </select>
        </div>
      </details>

      <%!-- Digital availability --%>
      <details class="group/py py-3" open={false}>
        <summary class="flex cursor-pointer list-none items-center justify-between py-1 font-semibold">
          Ketersediaan digital
          <.icon
            name="hero-chevron-down"
            class="size-4 text-base-content/40 group-open:rotate-180 transition-transform"
          />
        </summary>
        <div class="space-y-0.5 pb-2 pt-2">
          <button
            phx-click="filter"
            phx-value-field="has_ebook"
            phx-value-val="true"
            aria-pressed={if(@filters.has_ebook == "true", do: "true", else: "false")}
            class={[
              "flex w-full items-center gap-2 rounded-lg px-2.5 py-2 text-sm transition-colors text-left",
              @filters.has_ebook == "true" && "bg-primary/10 text-primary font-medium",
              @filters.has_ebook != "true" && "text-base-content/70 hover:bg-base-200"
            ]}
          >
            <.icon name="hero-device-tablet" class="size-4 shrink-0 text-primary/70" />
            <span class="flex-1">Punya e-book</span>
          </button>
          <button
            phx-click="filter"
            phx-value-field="has_ebook"
            phx-value-val="false"
            aria-pressed={if(@filters.has_ebook == "false", do: "true", else: "false")}
            class={[
              "flex w-full items-center gap-2 rounded-lg px-2.5 py-2 text-sm transition-colors text-left",
              @filters.has_ebook == "false" && "bg-primary/10 text-primary font-medium",
              @filters.has_ebook != "false" && "text-base-content/70 hover:bg-base-200"
            ]}
          >
            <.icon name="hero-archive-box" class="size-4 shrink-0 text-base-content/40" />
            <span class="flex-1">Koleksi fisik saja</span>
          </button>
        </div>
      </details>
    </div>
    """
  end

  attr :group, :atom, required: true
  attr :title, :string, required: true
  attr :field, :string, required: true
  attr :default_open, :boolean, default: false
  attr :searchable, :boolean, default: false
  attr :values, :list, required: true
  attr :all_values, :list, required: true
  attr :filters, :map, required: true
  attr :expanded, :boolean, default: false
  attr :dialog, :boolean, default: false
  attr :dom_id, :string, required: true

  defp facet_group(assigns) do
    selected = selected_filter(assigns.filters, assigns.group)

    assigns =
      assigns
      |> assign(:selected, selected)
      |> assign(:top_n, @facet_top_n)

    ~H"""
    <details
      :if={not facet_group_hidden?(@all_values, @selected)}
      class="group/py py-3"
      open={@default_open}
    >
      <summary class="flex cursor-pointer list-none items-center justify-between py-1 font-semibold">
        {@title}
        <.icon
          name="hero-chevron-down"
          class="size-4 text-base-content/40 group-open:rotate-180 transition-transform"
        />
      </summary>

      <div class="pb-2 pt-2 space-y-0.5">
        <div :if={@searchable and length(@all_values) > @top_n} class="pb-2">
          <input
            id={"facet-filter-#{@dom_id}-#{@group}"}
            type="search"
            placeholder="Cari dalam daftar…"
            aria-label={"Cari dalam daftar #{@title}"}
            class="input input-bordered input-sm w-full"
            phx-hook="FacetFilter"
            data-target={"facet-list-#{@dom_id}-#{@group}"}
          />
        </div>

        <ul id={"facet-list-#{@dom_id}-#{@group}"} class="space-y-0.5 max-h-64 overflow-y-auto pr-1">
          <li
            :for={item <- @values}
            data-facet-option
            data-label={String.downcase(item_label(item, @group) || "")}
          >
            <button
              phx-click="filter"
              phx-value-field={@field}
              phx-value-val={to_string(item.value)}
              aria-pressed={
                if(facet_active?(@filters, filter_key(@field), item.value), do: "true", else: "false")
              }
              class={[
                "flex w-full items-center gap-2 rounded-lg px-2.5 py-2 text-sm transition-colors text-left",
                facet_active?(@filters, filter_key(@field), item.value) &&
                  "bg-primary/10 text-primary font-medium",
                !facet_active?(@filters, filter_key(@field), item.value) &&
                  "text-base-content/70 hover:bg-base-200"
              ]}
            >
              <span
                :if={@group == :glam_types}
                class={["size-2 rounded-full shrink-0", glam_dot(item.value)]}
              ></span>
              <span class="truncate flex-1">{item_label(item, @group)}</span>
              <span class="text-xs text-base-content/40 shrink-0 tabular-nums">
                {format_count(item.count)}
              </span>
            </button>
          </li>
        </ul>

        <button
          :if={length(@all_values) > @top_n}
          phx-click="expand_group"
          phx-value-group={to_string(@group)}
          class="mt-1 inline-flex items-center gap-1 text-sm font-medium text-primary hover:underline"
        >
          <%= if @expanded do %>
            Tampilkan lebih sedikit
          <% else %>
            Lihat semua ({format_count(length(@all_values))})
          <% end %>
        </button>
      </div>
    </details>
    """
  end

  defp item_label(item, :units), do: item.label
  defp item_label(item, :glam_types), do: glam_label(item.value)
  defp item_label(item, :collection_types), do: type_label(item.value)
  defp item_label(item, :institution_types), do: institution_label(item.value)
  defp item_label(item, _group), do: String.trim(item.value || "")

  attr :value, :string, default: nil
  attr :selected, :boolean, default: false
  slot :inner_block, required: true

  defp option(assigns) do
    ~H"""
    <option value={@value} selected={@selected}>
      {render_slot(@inner_block)}
    </option>
    """
  end

  attr :col, :map, required: true
  attr :eager, :boolean, default: false

  defp collection_card(assigns) do
    col = assigns.col
    glam_type = col.resource_class && col.resource_class.glam_type

    assigns = assign(assigns, :glam_meta, glam_type && Map.get(@glam_meta, glam_type))

    ~H"""
    <div class="group bg-base-100 rounded-2xl border border-base-300/70 hover:border-primary/30 shadow-sm hover:shadow-lg hover:-translate-y-0.5 transition-all duration-300 overflow-hidden flex flex-col">
      <%!-- Book-aspect cover (3:4) — the old landscape h-44 strip cropped covers
           badly; this shows the cover at book proportions with the badge overlay. --%>
      <.cover col={@col} eager={@eager} class="rounded-none border-0 rounded-t-2xl">
        <:overlay>
          <span
            :if={@glam_meta}
            class={[
              "absolute top-3 left-3 z-10 inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-[11px] font-semibold backdrop-blur-md bg-base-100/80",
              @glam_meta.badge
            ]}
          >
            <.icon name={@glam_meta.icon} class="size-3" />
            {@glam_meta.label}
          </span>
        </:overlay>
      </.cover>

      <div class="p-4 space-y-2.5 flex flex-col flex-1">
        <div class="flex items-start justify-between gap-2">
          <h3 class="font-semibold text-sm leading-snug line-clamp-2 text-base-content">
            <.link
              navigate={~p"/collections/#{@col.id}"}
              class="hover:text-primary transition-colors"
              dir="auto"
            >
              {@col.title}
            </.link>
          </h3>
          <span
            :if={type_label(@col.collection_type)}
            class="text-[11px] bg-base-200 text-base-content/70 px-2 py-0.5 rounded-full shrink-0"
          >
            {type_label(@col.collection_type)}
          </span>
        </div>

        <p
          :if={@col.description}
          class="text-xs text-base-content/60 line-clamp-2 leading-relaxed"
          dir="auto"
        >
          {@col.description}
        </p>

        <div class="flex-1"></div>

        <div class="pt-2 border-t border-base-200/70 flex items-center gap-2">
          <span class="flex size-7 items-center justify-center rounded-lg bg-primary/10 text-primary shrink-0">
            <.icon name="hero-building-library" class="size-3.5" />
          </span>
          <div class="min-w-0">
            <p
              :if={@col.unit}
              class="text-xs font-medium text-base-content/80 truncate"
              title={@col.unit && @col.unit.name}
            >
              {@col.unit.name}
            </p>
            <p :if={@col.collection_code} class="text-[10px] font-mono text-base-content/40 truncate">
              {@col.collection_code}
            </p>
          </div>
        </div>

        <div class="pt-1">
          <.link
            navigate={~p"/collections/#{@col.id}"}
            class="flex items-center justify-center gap-1.5 w-full py-2 rounded-xl text-xs font-semibold text-primary border border-primary/30 group-hover:bg-primary group-hover:text-primary-content group-hover:border-primary transition-all duration-200"
          >
            Lihat koleksi <.icon name="hero-arrow-right" class="size-3.5" />
          </.link>
        </div>
      </div>
    </div>
    """
  end

  attr :col, :map, required: true
  attr :eager, :boolean, default: false

  defp collection_row(assigns) do
    col = assigns.col
    glam_type = col.resource_class && col.resource_class.glam_type

    assigns =
      assigns
      |> assign(:glam_type, glam_type)
      |> assign(:glam_meta, glam_type && Map.get(@glam_meta, glam_type))
      |> assign(:type_label, Map.get(@type_labels, col.collection_type))

    ~H"""
    <article class="relative grid grid-cols-[72px_minmax(0,1fr)] sm:grid-cols-[96px_minmax(0,1fr)] gap-3 sm:gap-5 py-4 border-b border-base-300/60 hover:bg-base-200/40 transition-colors">
      <.cover col={@col} eager={@eager} class="w-[72px] sm:w-24" />

      <div class="min-w-0">
        <h3 class="font-semibold text-lg leading-snug line-clamp-2 text-balance">
          <.link
            navigate={~p"/collections/#{@col.id}"}
            class="after:absolute after:inset-0 text-base-content hover:text-primary hover:underline underline-offset-2 transition-colors"
            dir="auto"
          >
            {@col.title}
          </.link>
        </h3>

        <p
          :if={@col.description}
          class="mt-1 text-sm text-base-content/70 line-clamp-2 lg:line-clamp-3 text-pretty"
          dir="auto"
        >
          {@col.description}
        </p>

        <div class="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1.5 text-xs text-base-content/50 relative z-10">
          <span
            :if={@glam_meta}
            class={[
              "inline-flex items-center gap-1 rounded-full border px-2 py-0.5",
              @glam_meta.badge
            ]}
          >
            <.icon name={@glam_meta.icon} class="size-3" />
            {@glam_meta.label}
          </span>

          <span :if={@type_label}>{@type_label}</span>

          <%!-- Org routes use /orgs/:slug which units don't expose yet — plain
               text until the org slug lands on the unit/profile payload. --%>
          <span :if={@col.unit} class="max-w-56 truncate">
            {@col.unit.name}
          </span>

          <span
            :if={@col.collection_code}
            class="inline-flex items-center gap-1 tabular-nums"
            title={@col.collection_code}
          >
            <span class="max-w-40 truncate font-mono">{@col.collection_code}</span>
            <button
              type="button"
              id={"copy-code-#{@col.id}"}
              phx-hook="CopyCode"
              data-code={@col.collection_code}
              aria-label="Salin kode koleksi"
              class="btn btn-ghost btn-xs btn-circle"
            >
              <.icon name="hero-clipboard" class="size-3.5" />
            </button>
          </span>
        </div>
      </div>
    </article>
    """
  end

  attr :col, :map, required: true
  attr :eager, :boolean, default: false
  attr :class, :string, default: nil
  slot :overlay, doc: "absolutely-positioned elements rendered on top of the cover"

  defp cover(assigns) do
    col = assigns.col
    assigns = assign(assigns, :hue, cover_hue(col.id))

    ~H"""
    <div
      id={"cover-#{@col.id}"}
      class={[
        "relative aspect-[3/4] overflow-hidden rounded border border-base-300/70 bg-base-200",
        @class
      ]}
      phx-hook="CoverFallback"
      data-hue={@hue}
      data-title={@col.title}
      data-org={@col.unit && @col.unit.name}
      data-type={type_label(@col.collection_type)}
    >
      <%= if @col.thumbnail do %>
        <img
          src={Public.asset_url(@col.thumbnail)}
          alt=""
          width="320"
          height="427"
          loading={if @eager, do: "eager", else: "lazy"}
          fetchpriority={if @eager, do: "high", else: nil}
          referrerpolicy="no-referrer"
          class="absolute inset-0 size-full object-cover transition-transform duration-500 group-hover:scale-105"
        />
      <% else %>
        <div class="cover-placeholder" style={"--h: #{@hue}"}>
          <small>{type_label(@col.collection_type)}</small>
          <span>{@col.title}</span>
          <small>{@col.unit && @col.unit.name}</small>
        </div>
      <% end %>
      {render_slot(@overlay)}
    </div>
    """
  end
end
