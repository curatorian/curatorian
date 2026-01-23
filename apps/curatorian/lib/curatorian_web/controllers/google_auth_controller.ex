defmodule CuratorianWeb.GoogleAuthController do
  use CuratorianWeb, :controller

  defdelegate request(conn, params), to: VoileWeb.GoogleAuthController
  defdelegate callback(conn, params), to: VoileWeb.GoogleAuthController
end
