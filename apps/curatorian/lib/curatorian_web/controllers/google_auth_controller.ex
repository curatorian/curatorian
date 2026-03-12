defmodule CuratorianWeb.GoogleAuthController do
  @moduledoc """
  Thin wrapper around the OAuth logic provided by Voile.

  We delegate to `VoileWeb.UserAuthGoogle` so the rest of the application
  does not need to depend directly on that module.  The controller simply
  forwards the request and callback phases.
  """

  use CuratorianWeb, :controller

  alias VoileWeb.UserAuthGoogle, as: Google

  def request(conn, _params) do
    Google.request(conn)
  end

  def callback(conn, _params) do
    Google.callback(conn)
  end
end
