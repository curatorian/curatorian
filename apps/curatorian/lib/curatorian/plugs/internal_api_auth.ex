defmodule Curatorian.Plugs.InternalApiAuth do
  @moduledoc """
  Authenticates internal API requests using a shared secret key.

  Used for cross-server communication between Curatorian and Atrium
  when they are deployed on different servers and cannot share cookies.

  ## Configuration

  Set the `INTERNAL_API_KEY` environment variable to a secure random string:

      INTERNAL_API_KEY=your-secure-random-key-here

  ## Usage

  Atrium must include the key in the `X-Internal-Key` header:

      curl -X POST https://curatorian.id/api/internal/auth/token \\
        -H "X-Internal-Key: your-secure-random-key-here" \\
        -H "Content-Type: application/json" \\
        -d '{"session_token": "..."}'

  ## Security

  - Uses `Plug.Crypto.secure_compare/2` to prevent timing attacks
  - Raises at startup if `INTERNAL_API_KEY` is not set
  - Returns 401 Unauthorized for invalid or missing keys
  """

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
