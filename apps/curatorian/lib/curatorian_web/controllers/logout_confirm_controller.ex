defmodule CuratorianWeb.LogoutConfirmController do
  @moduledoc """
  Renders a minimal auto-submitting logout form.

  Atrium's logout is a DELETE that 302-redirects here; a GET request cannot
  safely perform the state change itself, so this page performs a
  CSRF-protected POST (delete) on load and offers a manual fallback link.
  """

  use CuratorianWeb, :controller

  def confirm(conn, _params) do
    render(conn, :confirm)
  end
end
