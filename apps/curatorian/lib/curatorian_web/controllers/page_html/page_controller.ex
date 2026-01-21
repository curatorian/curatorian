defmodule CuratorianWeb.PageController do
  use CuratorianWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home)
  end

  def about(conn, _) do
    render(conn, :about)
  end
end
