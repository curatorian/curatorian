defmodule CuratorianWeb.SearchComponents do
  @moduledoc """
  Reusable search components for Curatorian's flagship cross-node collection
  discovery. Designed to work in plain (controller-rendered) HEEx templates as
  well as LiveViews — `search_bar/1` is a plain GET form that navigates to the
  discovery page, so it carries no LiveView-specific dependencies.
  """

  # Minimal imports (not `use CuratorianWeb, :html`) to avoid a self-import
  # cycle — html_helpers/1 in CuratorianWeb imports THIS module app-wide, so we
  # pull in only what we need directly.
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: CuratorianWeb.Endpoint,
    router: CuratorianWeb.Router,
    statics: CuratorianWeb.static_paths()

  import CuratorianWeb.CoreComponents

  @quick_filters [
    %{label: "Perpustakaan", glam_type: "Library", icon: "hero-book-open"},
    %{label: "Museum", glam_type: "Museum", icon: "hero-building-storefront"},
    %{label: "Arsip", glam_type: "Archive", icon: "hero-archive-box"},
    %{label: "Galeri", glam_type: "Gallery", icon: "hero-photo"}
  ]

  @doc """
  Renders a search bar that GET-navigates to the discovery page.

  ## Variants
    * `:hero`    — large, for the homepage hero over imagery
    * `:compact` — small, for embedding into headers/sections elsewhere

  Pass `:with_quick_filters` to render GLAM-sector chips beneath the input.
  """
  attr :id, :string, default: "search-bar"
  attr :value, :string, default: ""

  attr :placeholder, :string,
    default: "Cari koleksi, subjek, atau penulis di seluruh jaringan GLAM…"

  attr :variant, :atom, default: :compact
  attr :with_quick_filters, :boolean, default: false
  attr :class, :string, default: nil

  def search_bar(assigns) do
    ~H"""
    <div class={["w-full", @class]}>
      <form id={@id} action={~p"/collections"} method="get" role="search" class="relative w-full">
        <.icon
          name="hero-magnifying-glass"
          class="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 z-2"
        />
        <input
          type="text"
          name="q"
          value={@value}
          placeholder={@placeholder}
          aria-label="Cari koleksi"
          autocomplete="off"
          class={[
            "w-full border bg-base-100 text-base-content placeholder:text-base-content/40",
            "focus:outline-none transition-all duration-200 shadow-sm focus:shadow-lg",
            (@variant == :hero &&
               "h-14 rounded-2xl border-white/30 pl-12 pr-32 text-base backdrop-blur-md focus:border-primary") ||
              "h-11 rounded-xl border-base-300 pl-11 pr-28 text-sm focus:border-primary"
          ]}
        />
        <button
          type="submit"
          aria-label="Cari"
          class={[
            "absolute right-2 top-1/2 inline-flex -translate-y-1/2 items-center gap-1.5 font-semibold transition-all duration-200 cursor-pointer",
            (@variant == :hero &&
               "h-10 rounded-xl bg-primary px-5 text-primary-content hover:bg-primary-focus active:scale-[0.98]") ||
              "h-8 rounded-lg bg-primary/10 px-3 text-sm text-primary hover:bg-primary hover:text-primary-content active:scale-[0.98]"
          ]}
        >
          <.icon name="hero-arrow-right" class="size-4" />
          <span :if={@variant == :hero}>Cari</span>
        </button>
      </form>

      <.quick_filters :if={@with_quick_filters} />
    </div>
    """
  end

  defp quick_filters(assigns) do
    assigns = assign(assigns, :quick_filters, @quick_filters)

    ~H"""
    <div class="mt-4 flex flex-wrap items-center justify-center gap-2">
      <span class="text-xs font-medium text-violet-100/90">Jelajahi:</span>
      <.link
        :for={filter <- @quick_filters}
        navigate={~p"/collections?#{%{glam_type: filter.glam_type}}"}
        class={[
          "inline-flex items-center gap-1.5 rounded-full border border-violet-200/60 bg-violet-500/30 px-3 py-1",
          "text-xs font-semibold text-violet-50 backdrop-blur-sm transition-all duration-200",
          "hover:border-violet-100 hover:bg-violet-500/50 active:scale-95"
        ]}
      >
        <.icon name={filter.icon} class="size-3.5" />
        {filter.label}
      </.link>
    </div>
    """
  end

  # Make the quick-filter set available to callers/tests if needed.
  def quick_filter_options, do: @quick_filters
end
