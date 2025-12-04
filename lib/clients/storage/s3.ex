defmodule Clients.Storage.S3 do
  @moduledoc """
  Storage module for S3-compatible storage
  """

  @behaviour Clients.Storage

  @impl true
  def upload_from_path(tmp_path, content_type, context) do
    file_path = "#{context}/#{Ecto.UUID.generate()}.#{ext(content_type)}"

    file = File.read!(tmp_path)
    md5 = :md5 |> :crypto.hash(file) |> Base.encode64()

    get_client()
    |> AWS.S3.put_object(bucket_name(), file_path, %{
      "Body" => file,
      "ContentMD5" => md5,
      "Content-Type" => content_type
    })
    |> case do
      {:ok, _, %{status_code: 200}} ->
        {:ok, "#{endpoint()}/#{bucket_name()}/#{file_path}"}

      _ ->
        {:error, "Unable to upload file, please try again later."}
    end
  end

  @impl true
  def delete(file_url) do
    key = extract_key(file_url)

    get_client()
    |> AWS.S3.delete_object(bucket_name(), key, %{})
    |> case do
      {:ok, _, %{status_code: 204}} ->
        :ok

      _ ->
        {:error, "Unable to delete file"}
    end
  end

  defp get_client do
    access_key_id()
    |> AWS.Client.create(secret_key_access(), region())
    |> AWS.Client.put_endpoint("s3.#{region()}.backblazeb2.com")
  end

  defp endpoint do
    "https://s3.#{region()}.backblazeb2.com"
  end

  defp region, do: System.get_env("CURATORIAN_S3_REGION") || "us-west-002"
  defp access_key_id, do: System.get_env("CURATORIAN_S3_ACCESS_KEY_ID")
  defp secret_key_access, do: System.get_env("CURATORIAN_S3_SECRET_KEY_ACCESS")
  defp bucket_name, do: System.get_env("CURATORIAN_S3_BUCKET_NAME")

  defp extract_key(file_url) do
    prefix = "#{endpoint()}/#{bucket_name()}/"
    String.replace(file_url, prefix, "")
  end

  defp ext(content_type) do
    [ext | _] = MIME.extensions(content_type)
    ext
  end
end
