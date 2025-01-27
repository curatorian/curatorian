defmodule CuratorianWeb.PageController do
  use CuratorianWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    dbg(conn.request_path)
    render(conn, :home)
  end
end
