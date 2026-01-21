defmodule CuratorianWeb.ProfileHTML do
  use CuratorianWeb, :html

  alias CuratorianWeb.ProfileLayouts
  import CuratorianWeb.Utils.Basic.FormatIndonesiaTime

  embed_templates "*"

  def trim_description(description, number \\ 200) do
    description
    |> String.trim_trailing()
    |> HtmlSanitizeEx.strip_tags()
    |> String.slice(0..number)
    |> Kernel.<>("...")
  end

  def convert_time_zone_to_indonesia(time) do
    time
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!("Asia/Jakarta")
    |> format_indonesian_date()
  end
end
