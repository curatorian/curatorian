defmodule CuratorianWeb.Plugs.CSP do
  @moduledoc """
  Content-Security-Policy plug.

  Generates a per-request script nonce and sets the CSP header. Ships in
  **Report-Only** mode so violations surface in the browser console without
  breaking anything; set `CSP_ENFORCE=true` in the environment to switch to an
  enforcing header once the console is clean.

  Non-HTML requests (assets, webhooks, internal API) are skipped.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    nonce = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)

    header_name =
      if enforcing?(), do: "content-security-policy", else: "content-security-policy-report-only"

    conn
    |> assign(:script_nonce, nonce)
    |> put_resp_header(header_name, policy(nonce))
  end

  defp enforcing?, do: System.get_env("CSP_ENFORCE", "false") == "true"

  defp policy(nonce) do
    [
      "default-src 'self'",
      "script-src 'self' 'nonce-#{nonce}' https://challenges.cloudflare.com https://cdnjs.cloudflare.com https://cdn.jsdelivr.net",
      "worker-src 'self' blob:",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: blob: https:",
      "connect-src 'self' https://challenges.cloudflare.com",
      "frame-src https://challenges.cloudflare.com",
      "font-src 'self'",
      "object-src 'none'",
      "base-uri 'self'",
      "frame-ancestors 'self'",
      "report-uri /csp-report"
    ]
    |> Enum.join("; ")
  end
end
