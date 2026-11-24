defmodule CuratorianWeb.Public.Events.TimeFormatTest do
  @moduledoc "Timezone-aware event time rendering (audit #17)."

  use ExUnit.Case, async: true

  alias CuratorianWeb.Public.Events.TimeFormat

  describe "datetime/2" do
    test "renders in the event's timezone with the Indonesian label" do
      # 03:00 UTC == 10:00 WIB.
      dt = ~U[2026-03-10 03:00:00Z]

      assert TimeFormat.datetime(dt, "Asia/Jakarta") == "Tuesday, 10 March 2026 10:00 WIB"
    end

    test "uses Asia/Jakarta when no timezone is set" do
      dt = ~U[2026-03-10 03:00:00Z]

      assert TimeFormat.datetime(dt, nil) =~ "WIB"
      assert TimeFormat.datetime(dt, nil) =~ "10:00"
    end

    test "labels Central and Eastern Indonesian zones" do
      dt = ~U[2026-03-10 03:00:00Z]

      assert TimeFormat.datetime(dt, "Asia/Makassar") =~ "11:00 WITA"
      assert TimeFormat.datetime(dt, "Asia/Jayapura") =~ "12:00 WIT"
    end

    test "unknown zones render the zone name instead of a misleading WIB" do
      dt = ~U[2026-03-10 03:00:00Z]

      assert TimeFormat.datetime(dt, "Europe/London") =~ "Europe/London"
    end

    test "nil renders a dash" do
      assert TimeFormat.datetime(nil, "Asia/Jakarta") == "-"
    end

    test "handles NaiveDateTime columns (UTC) such as inserted_at" do
      assert TimeFormat.datetime(~N[2026-03-10 03:00:00], nil) =~ "10:00 WIB"
    end
  end

  describe "time/2" do
    test "renders only the clock time plus label" do
      dt = ~U[2026-03-10 03:00:00Z]

      assert TimeFormat.time(dt, "Asia/Jakarta") == "10:00 WIB"
      assert TimeFormat.time(nil, "Asia/Jakarta") == "-"
    end
  end

  describe "datetime_short/2" do
    test "renders a compact form" do
      dt = ~U[2026-03-10 03:00:00Z]

      assert TimeFormat.datetime_short(dt, "Asia/Jakarta") == "10 Mar 2026, 10:00 WIB"
    end
  end
end
