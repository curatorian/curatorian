defmodule CuratorianWeb.UserSessionController do
  @moduledoc """
  Handles login form submissions and logout for Curatorian's own auth flow.

  Routes:
    POST   /users/log_in   → create/2
    DELETE /users/log_out  → delete/2
  """

  use CuratorianWeb, :controller

  alias Curatorian.Accounts
  alias Curatorian.RateLimiter
  alias CuratorianWeb.UserAuth

  @doc "Called when the user submits the login form."
  def create(conn, %{"user" => _user_params} = params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params} = _params, _flash_message) do
    ip = remote_ip(conn)

    with :ok <- RateLimiter.check(:login, ip, 30, 3600),
         {:ok, _} <- verify_turnstile(conn.params, conn.remote_ip || conn.assigns[:remote_ip]) do
      %{"email" => login, "password" => password} = user_params

      case Accounts.get_user_by_login_and_password(login, password) do
        nil ->
          conn
          |> put_flash(:error, "Invalid email/username or password.")
          |> put_flash(:email, String.slice(login, 0, 160))
          |> redirect(to: ~p"/login")

        user ->
          if is_nil(user.confirmed_at) do
            conn
            |> put_flash(:error, "Please confirm your email address before logging in.")
            |> redirect(to: ~p"/login")
          else
            conn
            |> put_flash(:info, "Welcome back!")
            |> UserAuth.log_in_user(user, user_params)
          end
      end
    else
      {:error, :rate_limited} ->
        conn
        |> put_flash(:error, "Too many attempts from your network. Please try again later.")
        |> redirect(to: ~p"/login")

      {:error, _} ->
        conn
        |> put_flash(:error, "Captcha verification failed. Please complete the challenge.")
        |> redirect(to: ~p"/login")
    end
  end

  # Guard against a missing token raising inside the Turnstile library —
  # a request without the field is just a failed verification.
  defp verify_turnstile(params, remote_ip) do
    if Map.has_key?(params, "cf-turnstile-response") do
      Turnstile.verify(params, remote_ip)
    else
      {:error, :missing_turnstile_token}
    end
  end

  defp remote_ip(conn) do
    case conn.remote_ip do
      {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
      _ -> "unknown"
    end
  end

  @doc "Logs the current user out and redirects to the home page."
  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
