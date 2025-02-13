defmodule Clients.Storage.Local do
  @moduledoc """
  Storage module to store files locally
  """

  def upload(%{"file" => %Plug.Upload{path: tmp_path, content_type: content_type}}) do
    # Create upload dir if not exists

    create_uploads_dir()

    # Generate a unique filename
    file_name = "#{Ecto.UUID.generate()}.#{ext(content_type)}"

    case File.cp(tmp_path, Path.join(upload_dir(), file_name)) do
      :ok -> {:ok, Path.join("/uploads/contents", file_name)}
      error -> {:error, error}
    end
  end

  def delete(file_url) do
    "priv/static/"
    |> Path.join(file_url)
    |> File.rm()
    |> case do
      :ok -> {:ok}
      error -> {:error, error}
    end
  end

  defp ext(content_type) do
    [ext | _] = MIME.extensions(content_type)
    ext
  end

  defp upload_dir(), do: Path.join(["priv", "static", "uploads", "contents"])
  defp create_uploads_dir, do: File.mkdir_p!(upload_dir())
end
