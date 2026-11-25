defmodule CuratorianWeb.Public.Events.TimeFormat do
  @moduledoc """
  Event-time rendering for the public event pages.

  Times are stored in UTC; participants see the event's own timezone
  (default Asia/Jakarta) with the Indonesian zone label, not a raw UTC
  `DateTime.to_string` dump.

  Month and weekday names are Indonesian — the rest of these pages is in
  Bahasa Indonesia, so `Calendar.strftime`'s English names ("November",
  "Thursday") were jarring on the event page.
  """

  @weekdays %{
    "Monday" => "Senin",
    "Tuesday" => "Selasa",
    "Wednesday" => "Rabu",
    "Thursday" => "Kamis",
    "Friday" => "Jumat",
    "Saturday" => "Sabtu",
    "Sunday" => "Minggu"
  }

  @months %{
    "January" => "Januari",
    "February" => "Februari",
    "March" => "Maret",
    "April" => "April",
    "May" => "Mei",
    "June" => "Juni",
    "July" => "Juli",
    "August" => "Agustus",
    "September" => "September",
    "October" => "Oktober",
    "November" => "November",
    "December" => "Desember"
  }

  # Abbreviations used by datetime_short/2 ("10 Mar 2026").
  @months_short %{
    "January" => "Jan",
    "February" => "Feb",
    "March" => "Mar",
    "April" => "Apr",
    "May" => "Mei",
    "June" => "Jun",
    "July" => "Jul",
    "August" => "Agu",
    "September" => "Sep",
    "October" => "Okt",
    "November" => "Nov",
    "December" => "Des"
  }

  def datetime(nil, _tz), do: "-"
  def datetime(dt, tz), do: format(dt, tz, :long)

  def datetime_short(nil, _tz), do: "-"
  def datetime_short(dt, tz), do: format(dt, tz, :short)

  def time(nil, _tz), do: "-"
  def time(dt, tz), do: format(dt, tz, :time)

  @doc "Localized date only, e.g. `26 November 2026` (certificates)."
  def date(nil), do: "-"
  def date(%Date{} = date), do: localize(Calendar.strftime(date, "%d %B %Y"))
  def date(%DateTime{} = dt), do: date(DateTime.to_date(dt))
  def date(%NaiveDateTime{} = dt), do: date(NaiveDateTime.to_date(dt))
  def date(_), do: "-"

  defp format(dt, tz, style) do
    zone = tz || "Asia/Jakarta"

    case shift(dt, zone) do
      {:ok, shifted} ->
        localize(Calendar.strftime(shifted, strftime(style))) <> " " <> tz_label(zone)

      _ ->
        localize(Calendar.strftime(dt, strftime(style))) <> " UTC"
    end
  end

  defp strftime(:long), do: "%A, %d %B %Y %H:%M"
  defp strftime(:short), do: "%d %b %Y, %H:%M"
  defp strftime(:time), do: "%H:%M"

  defp localize(text) do
    Enum.reduce(@weekdays, text, fn {en, id}, acc -> String.replace(acc, en, id) end)
    |> then(fn acc ->
      Enum.reduce(@months, acc, fn {en, id}, inner -> String.replace(inner, en, id) end)
    end)
    |> then(fn acc ->
      # Long names are already replaced; this catches the 3-letter
      # abbreviations produced by %b (e.g. "Mar", "Oct").
      Enum.reduce(@months_short, acc, fn {en, id}, inner ->
        String.replace(inner, String.slice(en, 0, 3), id)
      end)
    end)
  end

  # inserted_at columns are NaiveDateTime (UTC) — normalize before shifting.
  defp shift(%NaiveDateTime{} = dt, zone),
    do: DateTime.from_naive(dt, "Etc/UTC") |> then(&shift_ok(&1, zone))

  defp shift(%DateTime{} = dt, zone), do: DateTime.shift_zone(dt, zone)
  defp shift(_, _zone), do: :error

  defp shift_ok({:ok, utc}, zone), do: DateTime.shift_zone(utc, zone)
  defp shift_ok({:error, _}, _zone), do: :error

  defp tz_label("Asia/Jakarta"), do: "WIB"
  defp tz_label("Asia/Makassar"), do: "WITA"
  defp tz_label("Asia/Jayapura"), do: "WIT"
  defp tz_label(zone), do: zone
end
