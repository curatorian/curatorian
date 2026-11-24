defmodule CuratorianWeb.ErrorHTMLTest do
  use CuratorianWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    html = render_to_string(CuratorianWeb.ErrorHTML, "404", "html", [])
    assert html =~ "404"
    assert html =~ "Halaman Tidak Ditemukan"
  end

  test "renders 500.html" do
    html = render_to_string(CuratorianWeb.ErrorHTML, "500", "html", [])
    assert html =~ "500"
    assert html =~ "Kesalahan Server Internal"
  end
end
