defmodule CuratorianWeb.Plugs.CrossAppCookie do
  @moduledoc """
  Writes or clears the shared cross-app token cookie on every request.

  Separate from Curatorian's main encrypted session cookie. Scoped to the
  apex domain so Atrium (on a different subdomain) can read it.

  Cookie name and domain MUST match Atrium's RequireVoileAuth plug exactly.

  ## Domain config

    Production:  CROSS_APP_COOKIE_DOMAIN=.curatorian.id
    Local dev:   CROSS_APP_COOKIE_DOMAIN=.curatorian.local
                 /etc/hosts entries required:
                   127.0.0.1  app.curatorian.local
                   127.0.0.1  billing.curatorian.local
  """

  import Plug.Conn

  # Must match Atrium's RequireVoileAuth plug exactly
  @cookie_name "_curatorian_cross_app_token"

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :cross_app_token) do
      nil -> conn
      token -> put_cross_app_cookie(conn, token)
    end
  end

  @doc "Writes the cross-app cookie. Call explicitly after login."
  def put_cross_app_cookie(conn, nil), do: conn

  def put_cross_app_cookie(conn, token) do
    put_resp_cookie(conn, @cookie_name, token,
      domain: cookie_domain(),
      http_only: true,
      secure: secure?(),
      same_site: "Lax",
      max_age: Curatorian.CrossAppToken.max_age()
    )
  end

  @doc "Clears the cross-app cookie. Call on logout."
  def delete_cross_app_cookie(conn) do
    delete_resp_cookie(conn, @cookie_name, domain: cookie_domain())
  end

  @doc "Returns the cookie name."
  def cookie_name, do: @cookie_name

  defp cookie_domain do
    System.get_env("CROSS_APP_COOKIE_DOMAIN") || ".curatorian.id"
  end

  defp secure? do
    Application.get_env(:curatorian, :env) != :dev
  end
end
