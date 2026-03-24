defmodule CuratorianWeb.Utils.Basic.FormatIndonesiaTime do
  # Date.day_of_week/1 returns 1..7 with Monday = 1, so list must start with Monday
  @days_of_week ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"]
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
  @default_offset_hours 7
  @default_separator "."

  @doc """
  Format a date (from UTC) into an Indonesian date string, e.g.
  "Senin, 24 Maret 2026".

  Accepts `DateTime`, `NaiveDateTime`, or `Date`. By default the input is
  treated as UTC and converted to WIB (UTC+7). You can override the offset
  with the `:offset_hours` option or change the time separator with
  `:separator` when using the full format.
  """
  def format_indonesian_date(datetime, opts \\ []) do
    ndt = to_local_naive_datetime(datetime, opts)

    day_of_week = get_day_of_week_from_naive(ndt)
    month = get_month_from_naive(ndt)

    "#{day_of_week}, #{ndt.day} #{month} #{ndt.year}"
  end

  @doc """
  Format a date + time (from UTC) into an Indonesian datetime string,
  e.g. "Senin, 24 Maret 2026 13.29". Uses a dot (`.`) as the default
  separator between hour and minute.
  """
  def format_full_indonesian_date(datetime, opts \\ []) do
    ndt = to_local_naive_datetime(datetime, opts)

    day_of_week = get_day_of_week_from_naive(ndt)
    month = get_month_from_naive(ndt)
    sep = Keyword.get(opts, :separator, @default_separator)

    "#{day_of_week}, #{ndt.day} #{month} #{ndt.year} #{pad_zero(ndt.hour)}#{sep}#{pad_zero(ndt.minute)}"
  end

  defp get_day_of_week_from_naive(%NaiveDateTime{} = ndt) do
    ndt
    |> NaiveDateTime.to_date()
    |> Date.day_of_week()
    |> then(&Enum.at(@days_of_week, &1 - 1))
  end

  defp get_month_from_naive(%NaiveDateTime{} = ndt) do
    Enum.at(@months, ndt.month - 1)
  end

  defp pad_zero(value) when value < 10, do: "0#{value}"
  defp pad_zero(value), do: "#{value}"

  # Convert various date/time inputs (assumed UTC) to a NaiveDateTime adjusted
  # by the configured offset (default UTC+7). This avoids relying on a
  # tzdata dependency while correctly shifting the wall-clock time.
  defp to_local_naive_datetime(%DateTime{} = dt, opts) do
    unix = DateTime.to_unix(dt)

    unix
    |> Kernel.+(offset_seconds(opts))
    |> DateTime.from_unix!(:second)
    |> DateTime.to_naive()
  end

  defp to_local_naive_datetime(%NaiveDateTime{} = ndt, opts) do
    # assume NaiveDateTime is stored as UTC in DB; attach UTC and shift
    dt = DateTime.from_naive!(ndt, "Etc/UTC")
    unix = DateTime.to_unix(dt)

    unix
    |> Kernel.+(offset_seconds(opts))
    |> DateTime.from_unix!(:second)
    |> DateTime.to_naive()
  end

  defp to_local_naive_datetime(%Date{} = date, opts) do
    {:ok, ndt} = NaiveDateTime.new(date, ~T[00:00:00])
    to_local_naive_datetime(ndt, opts)
  end

  defp offset_seconds(opts) do
    hours = Keyword.get(opts, :offset_hours, @default_offset_hours)
    hours * 3600
  end
end
