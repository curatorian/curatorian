defmodule CuratorianWeb.InternalAuthController do
  @moduledoc """
  Internal API controller for cross-app token issuance.

  This endpoint is called by Atrium when it needs to verify a session
  token and obtain a cross-app token. Used when Curatorian and Atrium
  are deployed on different servers and cannot share cookies.

  ## Endpoint

      POST /api/internal/auth/token

  ## Headers

      X-Internal-Key: <INTERNAL_API_KEY>
      Content-Type: application/json

  ## Request Body

      { "session_token": "<voile_session_token>" }

  ## Success Response (200)

      {
        "token": "<signed_cross_app_token>",
        "expires_in": 86400
      }

  ## Error Responses

  - 401: Invalid or expired session token
  - 422: Missing session_token or node data inconsistency
  - 500: Internal error
  """

  use CuratorianWeb, :controller

  alias Voile.Schema.Accounts

  @doc """
  Issues a cross-app token from a Voile session token.

  Atrium calls this when on a different server where shared cookie is unavailable.
  """
  def issue_token(conn, %{"session_token" => session_token}) do
    case Accounts.get_user_session_auth(session_token) do
      {:ok, auth_info} ->
        token = Curatorian.CrossAppToken.sign(auth_info)

        json(conn, %{
          token: token,
          expires_in: Curatorian.CrossAppToken.max_age()
        })

      {:error, :invalid_token} ->
        conn
        |> put_status(401)
        |> json(%{error: "invalid or expired session token"})

      {:error, :node_not_found} ->
        conn
        |> put_status(422)
        |> json(%{error: "node data inconsistency"})
    end
  end

  def issue_token(conn, _params) do
    conn
    |> put_status(422)
    |> json(%{error: "session_token is required"})
  end
end
