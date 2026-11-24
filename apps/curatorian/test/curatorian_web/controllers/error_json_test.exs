defmodule CuratorianWeb.ErrorJSONTest do
  use CuratorianWeb.ConnCase, async: true

  test "renders 404" do
    assert CuratorianWeb.ErrorJSON.render("404.json", %{}) == %{
             errors: %{code: 404, title: "Not Found", detail: "The requested resource could not be found."}
           }
  end

  test "renders 500" do
    assert CuratorianWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
