defmodule CuratorianWeb.Markdown do
  @moduledoc """
  Renders Markdown to sanitized HTML for display in templates.

  Uses MDEx (CommonMark/GFM via comrak) for parsing and HtmlSanitizeEx for
  sanitization. Raw HTML in the markdown source is escaped (`unsafe: false`)
  *and* scrubbed — user-generated content is safe to render.
  """

  @doc """
  Converts a Markdown string to a sanitized Phoenix.HTML.safe value.
  Returns `""` for nil/empty input.
  """
  @spec to_html(String.t() | nil) :: Phoenix.HTML.safe()
  def to_html(nil), do: Phoenix.HTML.raw("")
  def to_html(""), do: Phoenix.HTML.raw("")

  def to_html(markdown) when is_binary(markdown) do
    html =
      try do
        MDEx.to_html!(markdown,
          extension: [autolink: true, table: true, strikethrough: true],
          render: [unsafe: false],
          syntax_highlight: false
        )
      rescue
        _ -> markdown
      end

    sanitized = HtmlSanitizeEx.markdown_html(html)
    Phoenix.HTML.raw(sanitized)
  end
end
