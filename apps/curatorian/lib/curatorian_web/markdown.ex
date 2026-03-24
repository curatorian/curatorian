defmodule CuratorianWeb.Markdown do
  @moduledoc """
  Renders Markdown to sanitized HTML for display in templates.

  Uses Earmark for parsing and HtmlSanitizeEx for sanitization,
  ensuring user-generated content is safe to render.
  """

  # Earmark is included as an umbrella dep (via phoenix_markdown) and is
  # available at runtime, but Mix's cross-app static analysis can't always
  # verify it at compile time in umbrella apps.
  @compile {:no_warn_undefined, Earmark}

  @doc """
  Converts a Markdown string to a sanitized Phoenix.HTML.safe value.
  Returns `""` for nil/empty input.
  """
  @spec to_html(String.t() | nil) :: Phoenix.HTML.safe()
  def to_html(nil), do: Phoenix.HTML.raw("")
  def to_html(""), do: Phoenix.HTML.raw("")

  def to_html(markdown) when is_binary(markdown) do
    html =
      if Code.ensure_loaded?(Earmark) do
        case Earmark.as_html(markdown, smartypants: false, code_class_prefix: "language-") do
          {:ok, html, _warnings} -> IO.iodata_to_binary(html)
          {:error, html, _errors} -> IO.iodata_to_binary(html)
        end
      else
        require Logger
        Logger.warning("Earmark not available at runtime — falling back to raw markdown")
        markdown
      end

    sanitized = HtmlSanitizeEx.markdown_html(html)
    Phoenix.HTML.raw(sanitized)
  end
end
