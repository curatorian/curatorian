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
    conn = Google.callback(conn)

    # Google sign-in covers both first-time and returning users. Provision the
    # Atrium profile eagerly when a session was actually established.
    case conn.assigns[:current_scope] do
      %{user: %{id: user_id}} when is_binary(user_id) ->
        Curatorian.AtriumProfileSync.enqueue(user_id)

      _ ->
        :ok
    end

    conn
  end
end
