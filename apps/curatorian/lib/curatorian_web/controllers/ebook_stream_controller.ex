defmodule CuratorianWeb.EbookStreamController do
  @moduledoc """
  Session-gated streaming of readable e-book bytes.

  The reader fetches the file through this endpoint instead of the public
  /uploads URL, so:

    - the raw file URL never appears in the reader DOM
    - only confirmed, atrium-connected users can pull the bytes
    - the response is `inline`, `private, no-store`, and carries no filename,
      so browsers do not offer a "save" affordance and intermediaries do not
      cache the content
  """

  use CuratorianWeb, :controller

  alias Curatorian.Public

  @readable_mime ["application/pdf", "application/epub+zip"]

  def stream(conn, %{"id" => attachment_id}) do
    user = conn.assigns.current_scope && conn.assigns.current_scope.user

    cond do
      is_nil(user) ->
        conn |> put_status(:unauthorized) |> text("Unauthorized")

      is_nil(user.confirmed_at) or not Public.profile_connected?(user.id) ->
        conn |> put_status(:forbidden) |> text("Forbidden")

      true ->
        serve_attachment(conn, attachment_id)
    end
  end

  defp serve_attachment(conn, attachment_id) do
    attachment = Public.get_public_attachment(attachment_id)

    case attachment do
      %{mime_type: mime} = att when mime in @readable_mime ->
        source_url = Public.asset_url(att.file_path)

        if is_binary(source_url) do
          proxy_file(conn, source_url, mime)
        else
          conn |> put_status(:not_found) |> text("Not found")
        end

      _ ->
        conn |> put_status(:not_found) |> text("Not found")
    end
  end

  # Streams the file from Atrium storage through to the browser without ever
  # exposing the upstream URL to the client.
  defp proxy_file(conn, source_url, mime) do
    case Req.get(source_url,
           into: :self,
           finch: [name: Curatorian.Finch],
           headers: [{"accept", mime}]
         ) do
      {:ok, %Req.Response{status: 200, body: %Req.Response.Async{} = body_stream}} ->
        stream_to_client(conn, body_stream, mime)

      {:ok, %Req.Response{status: status}} ->
        require Logger

        Logger.warning("[ebook-stream] upstream returned #{status} for #{source_url}")
        conn |> put_status(:bad_gateway) |> text("Upstream error")

      {:error, exception} ->
        require Logger

        Logger.warning("[ebook-stream] upstream failed: #{Exception.message(exception)}")
        conn |> put_status(:bad_gateway) |> text("Upstream error")
    end
  end

  defp stream_to_client(conn, body_stream, mime) do
    conn =
      conn
      |> put_resp_content_type(mime)
      |> put_resp_header("content-disposition", "inline")
      |> put_resp_header("cache-control", "private, no-store")
      |> send_chunked(200)

    body_stream
    |> Stream.map(&encode_chunk/1)
    |> Enum.reduce_while(conn, fn chunk, acc_conn ->
      case Plug.Conn.chunk(acc_conn, chunk) do
        {:ok, conn} -> {:cont, conn}
        {:error, _} -> {:halt, conn}
      end
    end)
  end

  defp encode_chunk(chunk) when is_binary(chunk), do: chunk
  defp encode_chunk(chunk), do: IO.iodata_to_binary(chunk)
end
