defmodule Curatorian.CrossAppToken do
  @moduledoc """
  Issues signed tokens for cross-application authentication between
  Curatorian (issuer) and Atrium (verifier).

  Token is signed with Phoenix.Token using CuratorianWeb.Endpoint,
  backed by the app's SECRET_KEY_BASE.

  Atrium must share the same SECRET_KEY_BASE to verify these tokens.
  The @salt and @max_age_seconds MUST match Atrium's CrossAppToken module exactly.

  ## Token payload

      %{
        user_id:   string,          # UUID
        node_id:   integer,
        node_name: string,          # organization display name
        node_abbr: string,          # organization abbreviation
        roles:     [string]         # list of role name strings
      }

  ## Source of data

  All payload data comes from Voile.Schema.Accounts.get_user_session_auth/1,
  which combines session verification, role loading, and node identity
  into a single optimized call. Curatorian never queries Voile's database
  directly — it goes through Voile's context functions.
  """

  # Must match Atrium's CrossAppToken @salt exactly
  @salt "cross_app_user_auth"

  # 24 hours — must be >= Atrium's @max_age_seconds
  @max_age_seconds 86_400

  @doc """
  Signs a cross-app token from auth_info returned by
  Voile.Schema.Accounts.get_user_session_auth/1.

  ## Example

      {:ok, auth_info} = Voile.Schema.Accounts.get_user_session_auth(session_token)
      signed_token = Curatorian.CrossAppToken.sign(auth_info)

  ## Expected auth_info shape

      %{
        user_id:   binary(),
        node_id:   integer(),
        node_name: String.t(),
        node_abbr: String.t(),
        roles:     [%{name: String.t()}]
      }
  """
  def sign(%{
        user_id: user_id,
        node_id: node_id,
        node_name: node_name,
        node_abbr: node_abbr,
        roles: roles
      }) do
    payload = %{
      user_id: to_string(user_id),
      node_id: node_id,
      node_name: node_name,
      node_slug: node_abbr,
      roles: Enum.map(roles, & &1.name)
    }

    Phoenix.Token.sign(CuratorianWeb.Endpoint, @salt, payload)
  end

  @doc """
  Signs a cross-app token directly from a User struct.
  Works for Curatorian community users who may not have a node_id.
  The roles list must be preloaded on the user.
  """
  def sign_user(%Voile.Schema.Accounts.User{} = user) do
    roles =
      case user.roles do
        roles when is_list(roles) -> Enum.map(roles, & &1.name)
        _ -> []
      end

    payload = %{
      user_id: to_string(user.id),
      node_id: user.node_id,
      node_name: "",
      node_slug: "",
      roles: roles
    }

    Phoenix.Token.sign(CuratorianWeb.Endpoint, @salt, payload)
  end

  @doc """
  Verifies a cross-app token. Used for internal testing.
  Atrium performs its own verification using AtriumWeb.Endpoint with the same salt.
  """
  def verify(token) do
    Phoenix.Token.verify(CuratorianWeb.Endpoint, @salt, token, max_age: @max_age_seconds)
  end

  @doc "Returns the salt used for token signing."
  def salt, do: @salt

  @doc "Returns the max age in seconds for token validity."
  def max_age, do: @max_age_seconds
end
