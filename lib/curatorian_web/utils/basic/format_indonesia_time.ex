defmodule CuratorianWeb.Utils.Basic.FormatIndonesiaTime do
  @days_of_week ["Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"]
  @months [
    "Januari",
    "Februari",
    "Maret",
    "April",
    "Mei",
    "Juni",
    "Juli",
    "Agustus",
    "September",
    "Oktober",
    "November",
    "Desember"
  ]

  def format_indonesian_date(datetime) do
    day_of_week = get_day_of_week(datetime)
    month = get_month(datetime)

    "#{day_of_week}, #{datetime.day} #{month} #{datetime.year}"
  end

  def format_full_indonesian_date(datetime) do
    day_of_week = get_day_of_week(datetime)
    month = get_month(datetime)

    "#{day_of_week}, #{datetime.day} #{month} #{datetime.year} #{pad_zero(datetime.hour)}:#{pad_zero(datetime.minute)}"
  end

  defp get_day_of_week(datetime) do
    Enum.at(@days_of_week, Date.day_of_week(datetime) - 1)
  end

  defp get_month(datetime) do
    Enum.at(@months, datetime.month - 1)
  end

  defp pad_zero(value) when value < 10 do
    "0#{value}"
  end

  defp pad_zero(value), do: "#{value}"
end
