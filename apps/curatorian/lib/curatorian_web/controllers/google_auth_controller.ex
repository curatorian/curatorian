defmodule CuratorianWeb.GoogleAuthController do
  use CuratorianWeb, :controller
  alias CuratorianWeb.UserAuthGoogle

  def request(conn, _params) do
    UserAuthGoogle.request(conn)
  end

  def callback(conn, _params) do
    UserAuthGoogle.callback(conn)
  end
end
