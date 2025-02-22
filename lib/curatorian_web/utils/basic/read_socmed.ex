defmodule CuratorianWeb.Utils.Basic.ReadSocmed do
  def format_url("https" <> _ = url), do: url

  def format_url("http" <> rest) do
    "https" <> rest
  end

  def format_url("@" <> handle) do
    "https://twitter.com/#{handle}"
  end

  def format_url(url), do: "https://twitter.com/#{url}"

  def create_handler("https" <> _ = url) do
    url
    |> String.split("/")
    |> Enum.at(-1)
  end

  def create_handler("http" <> rest) do
    rest
    |> String.split("/")
    |> Enum.at(-1)
  end

  def create_handler("@" <> handle) do
    handle |> String.replace_leading("@", "")
  end

  def create_handler(handle) do
    handle
  end
end
