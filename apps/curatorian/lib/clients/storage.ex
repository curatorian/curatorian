defmodule Clients.Storage do
  @moduledoc """
  Behaviour for storage adapters
  """

  @callback upload_from_path(
              tmp_path :: String.t(),
              content_type :: String.t(),
              context :: String.t()
            ) :: {:ok, String.t()} | {:error, any()}
  @callback delete(file_url :: String.t()) :: :ok | {:error, any()}

  def adapter do
    Application.get_env(:curatorian, :storage_adapter, Clients.Storage.Local)
  end
end
