defmodule CuratorianWeb.UserSessionController do
  @moduledoc """
  Handles login form submissions and logout for Curatorian's own auth flow.

  Routes:
    POST   /users/log_in   → create/2
    DELETE /users/log_out  → delete/2
  """

  use CuratorianWeb, :controller

  alias Curatorian.Accounts
  alias CuratorianWeb.UserAuth

  @doc "Called when the user submits the login form."
  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params} = params, flash_message) do
    %{"email" => login, "password" => password} = user_params

    # When coming from registration we trust the user is confirmed (or skip the
    # check entirely — confirmation emails may not be enabled in all deployments).
    skip_confirmation_check = Map.get(params, "_action") == "registered"

    case Accounts.get_user_by_login_and_password(login, password) do
      nil ->
        conn
        |> put_flash(:error, "Invalid email/username or password.")
        |> put_flash(:email, String.slice(login, 0, 160))
        |> redirect(to: ~p"/login")

      user ->
        if not skip_confirmation_check and is_nil(user.confirmed_at) do
          conn
          |> put_flash(
            :error,
            "Please confirm your email address before logging in."
          )
          |> redirect(to: ~p"/login")
        else
          conn
          |> put_flash(:info, flash_message)
          |> UserAuth.log_in_user(user, user_params)
        end
    end
  end

  @doc "Logs the current user out and redirects to the home page."
  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
