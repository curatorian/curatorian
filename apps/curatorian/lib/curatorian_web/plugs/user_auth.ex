defmodule CuratorianWeb.UserAuth do
  @moduledoc """
  Curatorian's authentication plug — owns login/logout session management and
  cross-app token generation for Atrium integration.

  This module provides:
  - Session-based authentication using Voile.Schema.Accounts context functions
  - Cross-app token generation for Atrium (billing dashboard)
  - Cross-app cookie management for subdomain sharing
  - `on_mount` callbacks for LiveView session mounting
  - `require_authenticated_user/2` plug for controller pipelines

  ## Usage in Router (plug pipeline)

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_live_flash
        plug :put_root_layout, html: {CuratorianWeb.Layouts, :root}
        plug :protect_from_forgery
        plug :put_secure_browser_headers
        plug CuratorianWeb.UserAuth
        plug CuratorianWeb.Plugs.CrossAppCookie
      end

  ## Usage in LiveView (on_mount)

      # Mount scope but don't require auth:
      live_session :public, on_mount: [{CuratorianWeb.UserAuth, :mount_current_scope}] do
        live "/register", UserRegistrationLive, :new
      end

      # Require authenticated user:
      live_session :authenticated, on_mount: [{CuratorianWeb.UserAuth, :require_authenticated}] do
        live "/dashboard", DashboardLive, :index
      end
  """

  use CuratorianWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Voile.Schema.Accounts
  alias Voile.Schema.Accounts.Scope

  # Make the remember me cookie valid for 14 days.
  @max_cookie_age_in_days 14
  @remember_me_cookie "_curatorian_user_remember_me"
  @remember_me_options [
    sign: true,
    max_age: @max_cookie_age_in_days * 24 * 60 * 60,
    same_site: "Lax"
  ]

  # Session reissue age
  @session_reissue_age_in_days 7

  @doc """
  Plug init callback. Returns options unchanged.
  """
  def init(opts), do: opts

  @doc """
  Logs the user in.

  Creates a session token and cross-app token, then redirects.
  """
  def log_in_user(conn, user, params \\ %{}) do
    # Check if user is suspended
    if Accounts.is_manually_suspended?(user) do
      reason = user.suspension_reason || "Your account has been suspended"

      conn
      |> put_flash(:error, "Login failed: #{reason}. Please contact support for assistance.")
      |> redirect(to: "/login")
    else
      user_return_to = get_session(conn, :user_return_to)

      # Update last_login and last_login_ip
      ip =
        case Tuple.to_list(conn.remote_ip) do
          [a, b, c, d] -> Enum.join([a, b, c, d], ".")
          _ -> nil
        end

      Accounts.update_user_login(user, %{last_login: DateTime.utc_now(), last_login_ip: ip})

      conn
      |> create_or_extend_session(user, params)
      |> redirect(to: user_return_to || signed_in_path(user))
    end
  end

  @doc """
  Logs the user out.

  Clears session, deletes cross-app cookie, and redirects.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      CuratorianWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> CuratorianWeb.Plugs.CrossAppCookie.delete_cross_app_cookie()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the user by looking into the session and remember me token.

  Also generates cross-app token for Atrium integration.
  Will reissue the session token if it is older than the configured age.
  """
  def fetch_current_scope_for_user(conn, _opts) do
    with {token, conn} <- ensure_user_token(conn),
         {user, token_inserted_at} <- Accounts.get_user_by_session_token(token) do
      user = Voile.Repo.preload(user, [:user_role_assignments, :node, :roles, :user_type])

      # Check if user is suspended
      if Accounts.is_manually_suspended?(user) do
        conn
        |> put_flash(
          :error,
          "Your account has been suspended: #{user.suspension_reason || "Contact support for details"}"
        )
        |> log_out_user()
      else
        # Generate cross-app token for Atrium — use already-fetched user struct
        # (avoids a second DB round-trip and works even when user.node_id is nil)
        cross_app_token = generate_cross_app_token(user)

        conn
        |> assign(:current_scope, Scope.for_user(user))
        |> put_session(:cross_app_token, cross_app_token)
        |> maybe_reissue_user_session_token(user, token_inserted_at)
      end
    else
      nil -> assign(conn, :current_scope, Scope.for_user(nil))
    end
  end

  @doc """
  Plug callback - delegates to fetch_current_scope_for_user.
  """
  def call(conn, _opts) do
    fetch_current_scope_for_user(conn, [])
  end

  # Private functions

  defp generate_cross_app_token(%Voile.Schema.Accounts.User{} = user) do
    Curatorian.CrossAppToken.sign_user(user)
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, conn |> put_token_in_session(token) |> put_session(:user_remember_me, true)}
      else
        nil
      end
    end
  end

  defp maybe_reissue_user_session_token(conn, user, token_inserted_at) do
    token_age = DateTime.diff(DateTime.utc_now(:second), token_inserted_at, :day)

    if token_age >= @session_reissue_age_in_days do
      create_or_extend_session(conn, user, %{})
    else
      conn
    end
  end

  defp create_or_extend_session(conn, user, params) do
    token = Accounts.generate_user_session_token(user)
    remember_me = get_session(conn, :user_remember_me)

    # Generate cross-app token at session creation
    cross_app_token = generate_cross_app_token(user)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> put_session(:cross_app_token, cross_app_token)
    |> maybe_write_remember_me_cookie(token, params, remember_me)
  end

  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}, _),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, token, _params, true),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, _token, _params, _), do: conn

  defp write_remember_me_cookie(conn, token) do
    conn
    |> put_session(:user_remember_me, true)
    |> put_resp_cookie(@remember_me_cookie, token, @remember_me_options)
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, user_session_topic(token))
  end

  defp user_session_topic(token), do: "users_sessions:#{Base.url_encode64(token)}"

  # Note: These paths are handled by Voile's routes, not Curatorian's.
  # Curatorian is a frontend-only app that delegates to Voile for auth.
  defp signed_in_path(%Voile.Schema.Accounts.User{} = user) do
    user = Voile.Repo.preload(user, [:user_type, :roles])

    cond do
      Enum.any?(user.roles, &(&1.name == "super_admin")) -> "/manage"
      user.user_type && user.user_type.slug in ["administrator", "staff"] -> "/manage"
      user.user_type && String.starts_with?(user.user_type.slug, "member_") -> "/atrium"
      true -> "/"
    end
  end

  # LiveView on_mount callbacks - delegate to Voile's implementation
  # These are imported from VoileWeb.UserAuth in the router

  @doc """
  Disconnects existing sockets for the given tokens.
  """
  def disconnect_sessions(tokens) do
    Enum.each(tokens, fn %{token: token} ->
      CuratorianWeb.Endpoint.broadcast(user_session_topic(token), "disconnect", %{})
    end)
  end

  # ---------------------------------------------------------------------------
  # LiveView on_mount callbacks
  # ---------------------------------------------------------------------------

  @doc """
  Handles mounting and authenticating the current_scope in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_scope` — assigns `current_scope` based on the session
      user_token, or `nil` when there is no logged-in user.

    * `:require_authenticated` — same as `:mount_current_scope` but halts
      and redirects to `/login` when no authenticated user is found.
  """
  def on_mount(:mount_current_scope, _params, session, socket) do
    {:cont, mount_current_scope(socket, session)}
  end

  def on_mount(:require_authenticated, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if socket.assigns.current_scope && socket.assigns.current_scope.user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/login")

      {:halt, socket}
    end
  end

  @doc """
  Plug for controller pipelines that require an authenticated user.
  Stores the current path and redirects to `/login` when not authenticated.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns.current_scope && conn.assigns.current_scope.user do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/login")
      |> halt()
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp mount_current_scope(socket, session) do
    Phoenix.Component.assign_new(socket, :current_scope, fn ->
      {user, _} =
        if user_token = session["user_token"] do
          Accounts.get_user_by_session_token(user_token)
        end || {nil, nil}

      user =
        if user, do: Voile.Repo.preload(user, [:roles, :user_type, :node]), else: nil

      if user && Accounts.is_manually_suspended?(user) do
        Scope.for_user(nil)
      else
        Scope.for_user(user)
      end
    end)
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn
end
