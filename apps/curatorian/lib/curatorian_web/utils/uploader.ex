defmodule CuratorianWeb.Utils.Uploader do
  @moduledoc """
  Uploader module for handling file uploads in Trix editor.
  """

  def upload(%{"file" => %Plug.Upload{} = upload}) do
    Clients.Storage.adapter().upload_from_path(upload.path, upload.content_type, "trix")
  end

  def delete(key) do
    Clients.Storage.adapter().delete(key)
  end
end
