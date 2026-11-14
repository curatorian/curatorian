defmodule CuratorianWeb.MarkdownTest do
  use ExUnit.Case, async: true

  alias CuratorianWeb.Markdown

  describe "to_html/1" do
    test "renders bold and italic" do
      html = safe(Markdown.to_html("**bold** and *italic*"))

      assert html =~ "<strong>bold</strong>"
      assert html =~ "<em>italic</em>"
    end

    test "renders links" do
      html = safe(Markdown.to_html("[site](https://example.com)"))

      assert html =~ ~s(href="https://example.com")
    end

    test "strips javascript: links" do
      html = safe(Markdown.to_html("[click](javascript:alert(1))"))

      refute String.contains?(html, "javascript")
    end

    test "does not pass raw script tags through" do
      html = safe(Markdown.to_html("<script>alert(1)</script>\n\nafter"))

      refute String.contains?(html, "<script>")
    end

    test "renders GFM tables" do
      md = """
      | A | B |
      |---|---|
      | 1 | 2 |
      """

      html = safe(Markdown.to_html(md))

      assert html =~ "<table"
      assert html =~ "<td>1</td>"
    end

    test "returns empty for nil and empty input" do
      assert safe(Markdown.to_html(nil)) == ""
      assert safe(Markdown.to_html("")) == ""
    end
  end

  defp safe(raw_html) do
    {:safe, iodata} = raw_html
    IO.iodata_to_binary(iodata)
  end
end
