defmodule CuratorianWeb.Public.Events.TimeFormat do
  @moduledoc """
  Event-time rendering for the public event pages.

  Times are stored in UTC; participants see the event's own timezone
  (default Asia/Jakarta) with the Indonesian zone label, not a raw UTC
  `DateTime.to_string` dump.
  """

  def datetime(nil, _tz), do: "-"
  def datetime(dt, tz), do: format(dt, tz, "%A, %d %B %Y %H:%M")

  def datetime_short(nil, _tz), do: "-"

  def datetime_short(dt, tz), do: format(dt, tz, "%d %b %Y, %H:%M")

  def time(nil, _tz), do: "-"
  def time(dt, tz), do: format(dt, tz, "%H:%M")

  defp format(dt, tz, strftime_format) do
    zone = tz || "Asia/Jakarta"

    case shift(dt, zone) do
      {:ok, shifted} ->
        Calendar.strftime(shifted, strftime_format) <> " " <> tz_label(zone)

      _ ->
        Calendar.strftime(dt, strftime_format <> " UTC")
    end
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
