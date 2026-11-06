defmodule CuratorianWeb.SEOComponents do
  @moduledoc "SEO helpers: JSON-LD structured data and breadcrumbs."

  use Phoenix.Component

  import Phoenix.HTML, only: [raw: 1]
  import CuratorianWeb.CoreComponents, only: [icon: 1]

  @doc "Renders a JSON-LD <script> tag for the given structured-data map."
  attr :data, :map, required: true

  def json_ld(assigns) do
    assigns = assign(assigns, :json, json_script(assigns.data))

    ~H"""
    <script type="application/ld+json">
      <%= raw(@json) %>
    </script>
    """
  end

  @doc """
  Renders a visible breadcrumb trail plus a BreadcrumbList JSON-LD script.

  `trail` is a list of `{label, url}` tuples; the last entry (the current
  page) should have a `nil` url so it renders as plain text.
  """
  attr :trail, :list, required: true
  attr :class, :string, default: ""

  def breadcrumbs(assigns) do
    items = Enum.with_index(assigns.trail)
    assigns = assign(assigns, :items, items)

    ~H"""
    <nav
      aria-label="Breadcrumb"
      class={["flex items-center gap-2 text-sm text-base-content/50 flex-wrap", @class]}
    >
      <%= for {{label, path}, idx} <- @items do %>
        <%= if idx > 0 do %>
          <.icon name="hero-chevron-right-micro" class="w-3 h-3" />
        <% end %>
        <%= if path do %>
          <.link navigate={path} class="hover:text-primary transition-colors">
            {label}
          </.link>
        <% else %>
          <span class="truncate max-w-xs">{label}</span>
        <% end %>
      <% end %>
    </nav>
    <.json_ld data={breadcrumb_json(@trail)} />
    """
  end

  @doc """
  Encodes structured data as JSON safe for embedding in a <script> tag.
  """
  def json_script(data) do
    data
    |> Jason.encode!()
    |> String.replace("<", "\\u003C")
    |> String.replace(">", "\\u003E")
    |> String.replace("&", "\\u0026")
  end

  @doc "Formats a date as ISO-8601 for structured data; nil-safe."
  def iso_datetime(nil), do: nil
  def iso_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  def iso_datetime(%NaiveDateTime{} = dt), do: NaiveDateTime.to_iso8601(dt)

  defp breadcrumb_json(trail) do
    %{
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" =>
        trail
        |> Enum.with_index(1)
        |> Enum.map(fn {{label, path}, position} ->
          item = %{"@type" => "ListItem", "position" => position, "name" => label}
          if path, do: Map.put(item, "item", absolute_url(path)), else: item
        end)
    }
  end

  # Mirrors CuratorianWeb.Layouts.meta_base_url/absolute_url. Kept local to
  # avoid a compile-time cycle (Layouts templates import this module).
  defp base_url do
    System.get_env("CURATORIAN_URL") ||
      Application.get_env(:curatorian, :curatorian_url) ||
      CuratorianWeb.Endpoint.struct_url() |> URI.to_string()
  end

  defp absolute_url(nil), do: base_url()

  defp absolute_url(path) when is_binary(path) do
    if String.starts_with?(path, ["http://", "https://"]), do: path, else: base_url() <> path
  end
end
