defmodule CuratorianWeb.Plugs.GetCurrentPath do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    assign(conn, :current_uri, conn.request_path)
  end
end
