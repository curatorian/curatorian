defmodule CuratorianWeb.Pagination do
  @moduledoc """
  Generic, URL-driven pagination control.

  Renders prev/next + a windowed list of page numbers (with ellipsis for large
  ranges) plus a "Page X of Y" label. Each page is a `<.link patch>`, so callers
  pass a `:path` function that maps a page number to a URL string (preserving
  whatever filters/search that page uses).
  """

  use Phoenix.Component
  import CuratorianWeb.CoreComponents

  attr :current, :integer, required: true
  attr :total_pages, :integer, required: true
  attr :path, :any, required: true, doc: "1-arity fn: page -> URL string"
  attr :class, :string, default: nil

  def pagination(assigns) do
    ~H"""
    <div class={@class}>
      <nav class="flex flex-wrap items-center justify-center gap-1.5" aria-label="Pagination">
        <.link
          patch={@path.(max(@current - 1, 1))}
          class={btn_class(@current == 1)}
          aria-label="Halaman sebelumnya"
        >
          <.icon name="hero-chevron-left" class="size-4" />
        </.link>

        <%= for item <- page_items(@current, @total_pages) do %>
          <%= if item == :dots do %>
            <span class="px-1 text-base-content/40 select-none">…</span>
          <% else %>
            <.link
              patch={@path.(item)}
              class={page_class(item == @current)}
              aria-label={"Halaman #{item}"}
              aria-current={item == @current && "page"}
            >
              {item}
            </.link>
          <% end %>
        <% end %>

        <.link
          patch={@path.(min(@current + 1, @total_pages))}
          class={btn_class(@current == @total_pages)}
          aria-label="Halaman berikutnya"
        >
          <.icon name="hero-chevron-right" class="size-4" />
        </.link>
      </nav>

      <p class="mt-3 text-center text-xs text-base-content/50">
        Halaman {@current} dari {@total_pages}
      </p>
    </div>
    """
  end

  @doc "Windowed page list: page numbers with `:dots` placeholders for large ranges."
  def page_items(current, total) do
    cond do
      total <= 7 ->
        Enum.to_list(1..total)

      current <= 4 ->
        [1, 2, 3, 4, 5, :dots, total]

      current >= total - 3 ->
        [1, :dots, total - 4, total - 3, total - 2, total - 1, total]

      true ->
        [1, :dots, current - 1, current, current + 1, :dots, total]
    end
  end

  defp btn_class(true),
    do:
      "inline-flex items-center justify-center size-9 rounded-lg border border-base-200 text-base-content/30 pointer-events-none"

  defp btn_class(false),
    do:
      "inline-flex items-center justify-center size-9 rounded-lg border border-base-300 text-base-content/70 hover:bg-base-200"

  defp page_class(true),
    do:
      "inline-flex items-center justify-center min-w-9 h-9 px-2 rounded-lg border text-sm font-medium bg-primary text-primary-content border-primary"

  defp page_class(false),
    do:
      "inline-flex items-center justify-center min-w-9 h-9 px-2 rounded-lg border text-sm font-medium border-base-300 text-base-content/70 hover:bg-base-200"
end
