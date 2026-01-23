defmodule CuratorianWeb.UserSessionController do
  use CuratorianWeb, :controller

  alias Voile.Schema.Accounts

  defdelegate create(conn, params), to: VoileWeb.UserSessionController
  defdelegate delete(conn, params), to: VoileWeb.UserSessionController

  def update_password(conn, %{"user" => user_params}) do
    user = conn.assigns.current_scope.user

    case Accounts.update_user_password(user, user_params["password"], user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> redirect(to: ~p"/users/settings")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to update password.")
        |> redirect(to: ~p"/users/settings")
    end
  end
end
