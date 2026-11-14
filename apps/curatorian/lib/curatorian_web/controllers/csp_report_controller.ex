defmodule CuratorianWeb.CspReportController do
  @moduledoc """
  Receives browser CSP violation reports (report-uri from the CSP plug) and
  logs them so Report-Only rollout can be monitored. Unauthenticated by
  design — browsers don't attach credentials to violation reports.
  """

  use CuratorianWeb, :controller

  def report(conn, _params) do
    case conn.body_params do
      %{"csp-report" => report} ->
        require Logger

        Logger.warning(
          "[CSP] violation: blocked=#{report["blocked-uri"]} directive=#{report["effective-directive"]} source=#{report["source-file"]}:#{report["line-number"]}"
        )

      _ ->
        :ok
    end

    # 204 with no content — CSP reports expect an empty 2xx.
    send_resp(conn, 204, "")
  end
end
