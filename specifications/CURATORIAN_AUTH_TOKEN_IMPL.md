# Curatorian — Phoenix.Token Auth Implementation

## Context

Curatorian is the deployed host app wrapping Voile as a git dependency.
It owns `CuratorianWeb.Endpoint`, session management, and cross-app token issuance.
Voile provides three new context functions (see `VOILE_CONTEXT_ADDITIONS.md`) that
make Curatorian's token signing simple and efficient.

```
Voile (git dep)       owns: User, Node, Role schemas + auth context functions
      ↓ used by
Curatorian            owns: Endpoint, session, token issuance       ← YOU ARE HERE
      ↓ shared SECRET_KEY_BASE
Atrium                owns: billing, subscriptions, token verification
```

**Dependency:** Implement `VOILE_CONTEXT_ADDITIONS.md` first and run its tests
before starting this implementation. Curatorian calls `Voile.Accounts.get_user_session_auth/1`
as its primary session verification function.

---

## Token Payload

After this implementation the signed token carries:

```elixir
%{
  user_id:   "550e8400-e29b-41d4-a716-446655440000",  # UUID string
  node_id:   42,
  node_name: "SD Negeri 1 Bandung",
  node_slug: "sd-negeri-1-bandung",
  roles:     ["admin", "staff"]                         # role name strings
}
```

Atrium reads this on every request with zero database calls.

---

## Step 1 — Create the Cross-App Token Module

Create `lib/curatorian/cross_app_token.ex`:

```elixir
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
        node_slug: string,          # url-safe slug
        roles:     [string]         # list of role name strings
      }

  ## Source of data

  All payload data comes from Voile.Accounts.get_user_session_auth/1,
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
  Voile.Accounts.get_user_session_auth/1.

  ## Example

      {:ok, auth_info} = Voile.Accounts.get_user_session_auth(session_token)
      signed_token = Curatorian.CrossAppToken.sign(auth_info)

  ## Expected auth_info shape

      %{
        user_id:   binary(),
        node_id:   integer(),
        node_name: String.t(),
        node_slug: String.t(),
        roles:     [%{name: String.t(), slug: String.t()}]
      }
  """
  def sign(%{user_id: user_id, node_id: node_id, node_name: node_name,
             node_slug: node_slug, roles: roles}) do
    payload = %{
      user_id:   to_string(user_id),
      node_id:   node_id,
      node_name: node_name,
      node_slug: node_slug,
      roles:     Enum.map(roles, & &1.name)
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

  def salt, do: @salt
  def max_age, do: @max_age_seconds
end
```

---

## Step 2 — Modify `fetch_current_user/2` in `user_auth.ex`

This is the plug that runs on every authenticated request. Replace the existing
`get_user_by_session_token` call with `get_user_session_auth/1`:

```elixir
def fetch_current_user(conn, _opts) do
  {user_token, conn} = ensure_user_token(conn)

  case user_token && Voile.Accounts.get_user_session_auth(user_token) do
    {:ok, auth_info} ->
      cross_app_token = Curatorian.CrossAppToken.sign(auth_info)

      conn
      |> assign(:current_user_id, auth_info.user_id)
      |> assign(:current_node_id, auth_info.node_id)
      |> assign(:current_node_name, auth_info.node_name)
      |> put_session(:cross_app_token, cross_app_token)

    # Token errors — treat all as unauthenticated
    {:error, _reason} ->
      assign(conn, :current_user, nil)

    # user_token was nil
    nil ->
      assign(conn, :current_user, nil)

    # Fallback for existing callers that still expect :current_user struct
    # Remove this clause once all templates are migrated to use assigns above
    false ->
      assign(conn, :current_user, nil)
  end
end
```

> **Note:** If your existing templates reference `@current_user.fullname` or similar
> struct fields, you have two options:
> - Keep a second `get_user_by_session_token` call for the full struct assigned to
>   `:current_user`, and use `get_user_session_auth` only for the token
> - Migrate templates gradually to use `@current_user_id` and fetch display data
>   from a separate plug
>
> The simplest safe approach during migration:

```elixir
def fetch_current_user(conn, _opts) do
  {user_token, conn} = ensure_user_token(conn)

  # Existing full-user fetch for templates — keep as-is
  {user, _inserted_at} =
    (user_token && Voile.Accounts.get_user_by_session_token(user_token)) || {nil, nil}

  conn = assign(conn, :current_user, user)

  # New: lean auth fetch for cross-app token
  if user_token && user do
    case Voile.Accounts.get_user_session_auth(user_token) do
      {:ok, auth_info} ->
        cross_app_token = Curatorian.CrossAppToken.sign(auth_info)
        put_session(conn, :cross_app_token, cross_app_token)

      _ ->
        conn
    end
  else
    conn
  end
end
```

---

## Step 3 — Modify `log_in_user/2` in `user_auth.ex`

At login time you have the full `user` struct directly — use `get_user_with_roles/1`
since you already have the user and don't need session token verification again:

```elixir
def log_in_user(conn, user) do
  token = Voile.Accounts.generate_user_session_token(user)

  # Use get_user_with_roles/1 here (not get_user_session_auth/1) because we
  # already have the authenticated user — no need to re-verify the session token
  cross_app_token =
    case Voile.Accounts.get_user_with_roles(user.id) do
      {:ok, auth_data} ->
        case Voile.Nodes.get_node_basic(user.node_id) do
          {:ok, node} ->
            auth_info = Map.merge(auth_data, %{
              node_name: node.name,
              node_slug: node.slug
            })
            Curatorian.CrossAppToken.sign(auth_info)

          {:error, _} ->
            # Node not found — sign token without node metadata
            # This should not happen if data integrity is maintained
            Curatorian.CrossAppToken.sign(%{
              user_id:   user.id,
              node_id:   user.node_id,
              node_name: "",
              node_slug: "",
              roles:     auth_data.roles
            })
        end

      {:error, _} ->
        nil
    end

  conn
  |> put_session(:user_token, token)
  |> put_session(:cross_app_token, cross_app_token)
  |> CuratorianWeb.Plugs.CrossAppCookie.put_cross_app_cookie(cross_app_token)
  |> configure_session(renew: true)
  |> redirect(to: ~p"/dashboard")
end
```

> **Simpler alternative if you find the above verbose:** wait for `fetch_current_user/2`
> to fire on the first request after login (it always does) and let that build the token.
> Then `log_in_user/2` only needs to call `put_session(:user_token, token)`. The
> cross-app cookie will be set on the next request by the `CrossAppCookie` plug. This
> trades a small one-request window with no cross-app token for simpler code.

---

## Step 4 — Create the Cross-App Cookie Plug

Create `lib/curatorian_web/plugs/cross_app_cookie.ex`:

```elixir
defmodule CuratorianWeb.Plugs.CrossAppCookie do
  @moduledoc """
  Writes or clears the shared cross-app token cookie on every request.

  Separate from Curatorian's main encrypted session cookie. Scoped to the
  apex domain so Atrium (on a different subdomain) can read it.

  Cookie name and domain MUST match Atrium's RequireVoileAuth plug exactly.

  Domain config:
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
      nil   -> conn
      token -> put_cross_app_cookie(conn, token)
    end
  end

  @doc "Writes the cross-app cookie. Call explicitly after login."
  def put_cross_app_cookie(conn, nil), do: conn
  def put_cross_app_cookie(conn, token) do
    put_resp_cookie(conn, @cookie_name, token,
      domain:    cookie_domain(),
      http_only: true,
      secure:    secure?(),
      same_site: "Lax",
      max_age:   Curatorian.CrossAppToken.max_age()
    )
  end

  @doc "Clears the cross-app cookie. Call on logout."
  def delete_cross_app_cookie(conn) do
    delete_resp_cookie(conn, @cookie_name, domain: cookie_domain())
  end

  def cookie_name, do: @cookie_name

  defp cookie_domain do
    System.get_env("CROSS_APP_COOKIE_DOMAIN") || ".curatorian.id"
  end

  defp secure? do
    Application.get_env(:curatorian, :env) != :dev
  end
end
```

Add to browser pipeline in `lib/curatorian_web/router.ex`:

```elixir
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_live_flash
  plug :put_root_layout, html: {CuratorianWeb.Layouts, :root}
  plug :protect_from_forgery
  plug :put_secure_browser_headers
  plug CuratorianWeb.Plugs.CrossAppCookie   # ADD — after fetch_session
end
```

---

## Step 5 — Handle Logout

In `log_out_user/1` in `user_auth.ex`:

```elixir
def log_out_user(conn) do
  user_token = get_session(conn, :user_token)
  user_token && Voile.Accounts.delete_user_session_token(user_token)

  conn
  |> clear_session()
  |> CuratorianWeb.Plugs.CrossAppCookie.delete_cross_app_cookie()  # ADD
  |> redirect(to: ~p"/")
end
```

---

## Step 6 — Approach B: Internal API Endpoint (cross-server fallback)

Add now, use later when Curatorian and Atrium are on different servers.

Create `lib/curatorian/plugs/internal_api_auth.ex`:

```elixir
defmodule Curatorian.Plugs.InternalApiAuth do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    expected = System.get_env("INTERNAL_API_KEY") || raise("INTERNAL_API_KEY not set")
    provided = get_req_header(conn, "x-internal-key") |> List.first()

    if Plug.Crypto.secure_compare(expected, provided || "") do
      conn
    else
      conn
      |> put_status(401)
      |> Phoenix.Controller.json(%{error: "unauthorized"})
      |> halt()
    end
  end
end
```

Create `lib/curatorian_web/controllers/internal_auth_controller.ex`:

```elixir
defmodule CuratorianWeb.InternalAuthController do
  use CuratorianWeb, :controller

  @doc """
  POST /api/internal/auth/token
  Header: X-Internal-Key: <INTERNAL_API_KEY>
  Body:   { "session_token": "<voile_session_token>" }

  Atrium calls this when on a different server where shared cookie is unavailable.
  """
  def issue_token(conn, %{"session_token" => session_token}) do
    case Voile.Accounts.get_user_session_auth(session_token) do
      {:ok, auth_info} ->
        token = Curatorian.CrossAppToken.sign(auth_info)
        json(conn, %{token: token, expires_in: Curatorian.CrossAppToken.max_age()})

      {:error, :invalid_token} ->
        conn |> put_status(401) |> json(%{error: "invalid or expired session token"})

      {:error, :node_not_found} ->
        conn |> put_status(422) |> json(%{error: "node data inconsistency"})

      {:error, _} ->
        conn |> put_status(500) |> json(%{error: "internal error"})
    end
  end

  def issue_token(conn, _params) do
    conn |> put_status(422) |> json(%{error: "session_token is required"})
  end
end
```

Add to `lib/curatorian_web/router.ex`:

```elixir
pipeline :internal_api do
  plug :accepts, ["json"]
  plug Curatorian.Plugs.InternalApiAuth
end

scope "/api/internal", CuratorianWeb do
  pipe_through :internal_api
  post "/auth/token", InternalAuthController, :issue_token
end
```

---

## Step 7 — Tests

Create `test/curatorian/cross_app_token_test.exs`:

```elixir
defmodule Curatorian.CrossAppTokenTest do
  use Curatorian.DataCase, async: true

  alias Curatorian.CrossAppToken

  # Mimics the map returned by Voile.Accounts.get_user_session_auth/1
  defp mock_auth_info(overrides \\ %{}) do
    Map.merge(
      %{
        user_id:   Ecto.UUID.generate(),
        node_id:   42,
        node_name: "SD Negeri 1 Bandung",
        node_slug: "sd-negeri-1-bandung",
        roles:     [%{name: "admin", slug: "admin"}, %{name: "staff", slug: "staff"}]
      },
      overrides
    )
  end

  describe "sign/1" do
    test "returns a binary token" do
      token = CrossAppToken.sign(mock_auth_info())
      assert is_binary(token)
      assert String.length(token) > 20
    end
  end

  describe "verify/1" do
    test "round-trips a signed token with all payload fields" do
      auth_info = mock_auth_info()
      token = CrossAppToken.sign(auth_info)

      assert {:ok, claims} = CrossAppToken.verify(token)
      assert claims.user_id   == to_string(auth_info.user_id)
      assert claims.node_id   == auth_info.node_id
      assert claims.node_name == auth_info.node_name
      assert claims.node_slug == auth_info.node_slug
      assert "admin" in claims.roles
      assert "staff" in claims.roles
    end

    test "roles are encoded as name strings, not structs" do
      token = CrossAppToken.sign(mock_auth_info())
      {:ok, claims} = CrossAppToken.verify(token)

      assert Enum.all?(claims.roles, &is_binary/1)
    end

    test "returns error for tampered token" do
      assert {:error, :invalid} = CrossAppToken.verify("not.a.real.token")
    end

    test "handles user with no roles" do
      auth_info = mock_auth_info(%{roles: []})
      token = CrossAppToken.sign(auth_info)
      {:ok, claims} = CrossAppToken.verify(token)
      assert claims.roles == []
    end

    test "handles empty node_name gracefully" do
      auth_info = mock_auth_info(%{node_name: "", node_slug: ""})
      token = CrossAppToken.sign(auth_info)
      {:ok, claims} = CrossAppToken.verify(token)
      assert claims.node_name == ""
    end
  end
end
```

Create `test/curatorian_web/plugs/cross_app_cookie_test.exs`:

```elixir
defmodule CuratorianWeb.Plugs.CrossAppCookieTest do
  use CuratorianWeb.ConnCase, async: true

  alias CuratorianWeb.Plugs.CrossAppCookie
  alias Curatorian.CrossAppToken

  defp valid_token do
    CrossAppToken.sign(%{
      user_id:   Ecto.UUID.generate(),
      node_id:   1,
      node_name: "Test Library",
      node_slug: "test-library",
      roles:     [%{name: "staff", slug: "staff"}]
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

  test "put_cross_app_cookie/2 is a no-op for nil token", %{conn: conn} do
    conn = CrossAppCookie.put_cross_app_cookie(conn, nil)
    refute conn.resp_cookies[CrossAppCookie.cookie_name()]
  end

  test "delete_cross_app_cookie/1 expires the cookie", %{conn: conn} do
    conn = CrossAppCookie.delete_cross_app_cookie(conn)
    cookie = conn.resp_cookies[CrossAppCookie.cookie_name()]
    assert cookie[:max_age] == 0
  end
end
```

---

## Step 8 — Environment Variables

```bash
# Must be IDENTICAL to Atrium's SECRET_KEY_BASE
SECRET_KEY_BASE=<mix phx.gen.secret>

# Cookie domain — must cover both Curatorian and Atrium subdomains
# Production: .curatorian.id
# Local dev:  .curatorian.local
CROSS_APP_COOKIE_DOMAIN=.curatorian.id

# For Approach B (internal API, cross-server)
INTERNAL_API_KEY=<mix phx.gen.secret 32>
```

```elixir
# config/runtime.exs
config :curatorian, CuratorianWeb.Endpoint,
  secret_key_base:
    System.get_env("SECRET_KEY_BASE") ||
      raise("SECRET_KEY_BASE missing — must match Atrium's value exactly")
```

---

## Summary of Files

| Action | File |
|---|---|
| **Create** | `lib/curatorian/cross_app_token.ex` |
| **Create** | `lib/curatorian_web/plugs/cross_app_cookie.ex` |
| **Create** | `lib/curatorian/plugs/internal_api_auth.ex` |
| **Create** | `lib/curatorian_web/controllers/internal_auth_controller.ex` |
| **Modify** | `lib/curatorian_web/router.ex` |
| **Modify** | `lib/curatorian_web/user_auth.ex` — `fetch_current_user/2`, `log_in_user/2`, `log_out_user/1` |
| **Modify** | `config/runtime.exs` |
| **Create** | `test/curatorian/cross_app_token_test.exs` |
| **Create** | `test/curatorian_web/plugs/cross_app_cookie_test.exs` |

---

## Important Constraints

- **Never modify Voile's source** for this feature — call its context functions only
- `get_user_session_auth/1` is the primary call in `fetch_current_user/2`
- `get_user_with_roles/1` + `get_node_basic/1` are used in `log_in_user/2`
- `@salt` (`"cross_app_user_auth"`) and `@max_age_seconds` (`86_400`) must match Atrium exactly
- `SECRET_KEY_BASE` must be identical between Curatorian and Atrium
- After `mix deps.update voile`: re-run Curatorian's tests — if Voile's Role schema
  changes (e.g. `:name` renamed), `CrossAppToken.sign/1` will break with a clear error
