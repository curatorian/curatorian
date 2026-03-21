defmodule CuratorianWeb.Plugs.CrossAppCookieTest do
  use CuratorianWeb.ConnCase, async: true

  alias CuratorianWeb.Plugs.CrossAppCookie
  alias Curatorian.CrossAppToken

  defp valid_token do
    CrossAppToken.sign(%{
      user_id: Ecto.UUID.generate(),
      node_id: 1,
      node_name: "SD Negeri 1 Bandung",
      node_abbr: "SDN1BDG",
      roles: [%{name: "admin"}]
    })
  end

  test "sets cross-app cookie when token is in session", %{conn: conn} do
    token = valid_token()

    conn =
      conn
      |> init_test_session(%{cross_app_token: token})
      |> CrossAppCookie.call([])

    assert conn.resp_cookies[CrossAppCookie.cookie_name()]
  end

  test "does not set cookie when no token in session", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{})
      |> CrossAppCookie.call([])

    refute conn.resp_cookies[CrossAppCookie.cookie_name()]
  end

  test "without remember_me: cookie has no max_age (session cookie)", %{conn: conn} do
    token = valid_token()

    conn =
      conn
      |> init_test_session(%{cross_app_token: token, user_remember_me: false})
      |> CrossAppCookie.call([])

    cookie = conn.resp_cookies[CrossAppCookie.cookie_name()]
    assert cookie
    refute Map.has_key?(cookie, :max_age)
  end

  test "with remember_me: cookie has max_age set (persists across browser restarts)", %{
    conn: conn
  } do
    token = valid_token()

    conn =
      conn
      |> init_test_session(%{cross_app_token: token, user_remember_me: true})
      |> CrossAppCookie.call([])

    cookie = conn.resp_cookies[CrossAppCookie.cookie_name()]
    assert cookie
    assert cookie.max_age == 14 * 24 * 60 * 60
  end

  test "put_cross_app_cookie/2 is a no-op for nil token", %{conn: conn} do
    conn = CrossAppCookie.put_cross_app_cookie(conn, nil)
    refute conn.resp_cookies[CrossAppCookie.cookie_name()]
  end

  test "put_cross_app_cookie/2 sets a session cookie by default", %{conn: conn} do
    token = valid_token()
    conn = CrossAppCookie.put_cross_app_cookie(conn, token, [])

    cookie = conn.resp_cookies[CrossAppCookie.cookie_name()]
    assert cookie
    assert cookie.value == token
    assert cookie.http_only == true
    refute Map.has_key?(cookie, :max_age)
  end

  test "put_cross_app_cookie/2 sets max_age when remember_me: true", %{conn: conn} do
    token = valid_token()
    conn = CrossAppCookie.put_cross_app_cookie(conn, token, remember_me: true)

    cookie = conn.resp_cookies[CrossAppCookie.cookie_name()]
    assert cookie.max_age == 14 * 24 * 60 * 60
  end

  test "delete_cross_app_cookie/1 expires the cookie", %{conn: conn} do
    conn = CrossAppCookie.delete_cross_app_cookie(conn)
    cookie = conn.resp_cookies[CrossAppCookie.cookie_name()]
    assert cookie[:max_age] == 0
  end

  test "cookie_name/0 returns the expected name" do
    assert CrossAppCookie.cookie_name() == "_curatorian_cross_app_token"
  end
end
