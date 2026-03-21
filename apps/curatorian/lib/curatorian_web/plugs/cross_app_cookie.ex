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

  # 14 days in seconds — must stay in sync with UserAuth @max_cookie_age_in_days
  @remember_me_max_age_seconds 14 * 24 * 60 * 60

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :cross_app_token) do
      nil ->
        conn

      token ->
        # Mirror the Curatorian session's persistence: only set a long-lived cookie
        # when remember_me is active. Without it, use a session cookie (no max_age)
        # so the cross-app cookie expires when the browser is closed — matching
        # Curatorian's own session cookie behaviour and preventing Atrium from
        # remaining logged in after Curatorian has logged out.
        remember_me = get_session(conn, :user_remember_me) == true
        put_cross_app_cookie(conn, token, remember_me: remember_me)
    end
  end

  @doc """
  Writes the cross-app cookie.

  Options:
    * `:remember_me` - when `true`, sets `max_age` to 14 days so the cookie
      survives browser restarts (mirrors Curatorian's remember-me cookie).
      When `false` (default), the cookie has no `max_age` and is cleared
      when the browser session ends.
  """
  def put_cross_app_cookie(conn, token, opts \\ [])
  def put_cross_app_cookie(conn, nil, _opts), do: conn

  def put_cross_app_cookie(conn, token, opts) when is_list(opts) do
    remember_me = Keyword.get(opts, :remember_me, false)

    base_opts = [
      http_only: true,
      secure: secure?(),
      same_site: "Lax"
    ]

    # Only persist the cookie across browser restarts when remember_me is active.
    # Without max_age the browser treats it as a session cookie.
    base_opts =
      if remember_me do
        Keyword.put(base_opts, :max_age, @remember_me_max_age_seconds)
      else
        base_opts
      end

    # On localhost, omit the domain attribute entirely.
    # "localhost" as a domain value is inconsistently handled across browsers;
    # host-only cookies (no domain) are reliably shared across ports on the same host.
    opts =
      case cookie_domain() do
        d when d in [nil, "", "localhost"] -> base_opts
        domain -> Keyword.put(base_opts, :domain, domain)
      end

    put_resp_cookie(conn, @cookie_name, token, opts)
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
