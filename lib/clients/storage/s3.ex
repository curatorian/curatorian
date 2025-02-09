# defmodule Clients.Storage.S3 do
#   @moduledoc false

#   @b2_region Application.compile_env!(:my_app, :b2_region)
#   @b2_access_key_id Application.compile_env!(:my_app, :b2_access_key_id)
#   @b2_secret_key_access Application.compile_env!(:my_app, :b2_secret_key_access)
#   @b2_bucket_name Application.compile_env!(:my_app, :b2_bucket_name)

#   def upload(%{"Content-Type" => content_type, "file" => %Plug.Upload{path: tmp_path}}) do
#     file_path = "public/#{Ecto.UUID.generate()}.#{ext(content_type)}"

#     file = File.read!(tmp_path)
#     md5 = :md5 |> :crypto.hash(file) |> Base.encode64()

#     get_client()
#     |> AWS.S3.put_object(@b2_bucket_name, file_path, %{
#       "Body" => file,
#       "ContentMD5" => md5,
#       "Content-Type" => content_type
#     })
#     |> case do
#       {:ok, _, %{status_code: 200}} ->
#         {:ok, "#{endpoint()}/#{@b2_bucket_name}/#{file_path}"}

#       _ = response ->
#         {:error, "Unable to upload file, please try again later."}
#     end
#   end

#   defp get_client do
#     @b2_application_key_id
#     |> AWS.Client.create(@b2_application_key, @b2_region)
#     # This line might be irrelevant for you if you are not using backblaze
#     |> AWS.Client.put_endpoint("s3.#{@b2_region}.backblazeb2.com")
#   end

#   defp endpoint do
#     "https://s3.#{@b2_region}.backblazeb2.com"
#   end
# end
