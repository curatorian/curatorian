defmodule CuratorianWeb.Utils.Basic.ReadSocmed do
  @social_media_domains %{
    "twitter.com" => "https://twitter.com/",
    "instagram.com" => "https://instagram.com/",
    "facebook.com" => "https://facebook.com/",
    "linkedin.com" => "https://linkedin.com/in/",
    "github.com" => "https://github.com/"
  }

  def format_url("https" <> _ = url), do: url
  def format_url("http" <> rest), do: "https" <> rest
  def format_url("@" <> handle), do: format_handle(handle, "twitter.com")

  def format_url(url) do
    case String.split(url, "/", parts: 2) do
      [platform, handle] ->
        if Map.has_key?(@social_media_domains, platform) do
          format_handle(handle, platform)
        else
          format_handle(url, "curatorian.id")
        end

      _ ->
        format_handle(url, "curatorian.id")
    end
  end

  defp format_handle(handle, platform) do
    base_url = Map.get(@social_media_domains, platform, "https://curatorian.id/")
    base_url <> handle
  end

  def create_handler("https://" <> url), do: extract_handler(url)
  def create_handler("http://" <> url), do: extract_handler(url)
  def create_handler("@" <> handle), do: String.replace_leading(handle, "@", "")
  def create_handler(handle), do: handle

  defp extract_handler(url) do
    url
    |> String.split("/")
    |> List.last()
  end
end
