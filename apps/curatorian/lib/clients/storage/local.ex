defmodule Clients.Storage.Local do
  @moduledoc """
  Storage module to store files locally with dynamic directory support
  """

  @behaviour Clients.Storage

  @default_context "contents"

  def upload_from_path(tmp_path, content_type, context \\ @default_context) do
    # Create upload dir if not exists
    create_uploads_dir(context)

    # Generate a unique filename
    file_name = "#{Ecto.UUID.generate()}.#{ext(content_type)}"

    dest_path = Path.join(upload_dir(context), file_name)

    case File.cp(tmp_path, dest_path) do
      :ok -> {:ok, Path.join("/uploads/#{context}", file_name)}
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

  defp upload_dir(context), do: Path.join(["priv", "static", "uploads", context])
  defp create_uploads_dir(context), do: File.mkdir_p!(upload_dir(context))
end
