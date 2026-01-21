defmodule CuratorianWeb.Utils.TrixUploadsController do
  use CuratorianWeb, :controller

  def create(conn, params) do
    case impl().upload(params) do
      {:ok, file_url} -> send_resp(conn, 201, file_url)
      {:error, reason} -> send_resp(conn, 400, "Error: #{reason}")
    end
  end

  def delete(conn, %{"key" => key}) do
    case impl().delete(key) do
      {:ok} -> send_resp(conn, 204, "File successfully deleted")
      {:error, reason} -> send_resp(conn, 400, "Error: #{reason}")
    end
  end

  defp impl, do: Application.get_env(:curatorian, :uploader)
end
