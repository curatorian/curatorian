defmodule Curatorian.Public.EventCheckpointTest do
  @moduledoc """
  Session-code check-in from the public participant page (`/r/:token`).

  `record_checkpoint_attendance/2` must resolve the code against the
  registration's **own event**: codes are unique per event, so another
  event's code must be rejected (a global lookup could also raise on
  duplicate codes across events, and let a participant record attendance
  for an event they are not part of).
  """

  use Curatorian.DataCase, async: true

  alias Curatorian.Public
  alias Curatorian.Public.EventCheckpointRecord

  describe "record_checkpoint_attendance/2" do
    test "records attendance for the registration's own event (case-insensitive)" do
      event = event_fixture()
      checkpoint = checkpoint_fixture(event, "SESS01")
      registration = registration_fixture(event)

      assert {:ok, :recorded} =
               Public.record_checkpoint_attendance(registration.id, "sess01")

      assert [%{checkpoint_id: checkpoint_id}] = Public.list_checkpoint_records(registration.id)
      assert checkpoint_id == checkpoint.id
    end

    test "does not match a code from another event, even with duplicate codes" do
      event_a = event_fixture()
      event_b = event_fixture()
      checkpoint_a = checkpoint_fixture(event_a, "SHARED")
      _checkpoint_b = checkpoint_fixture(event_b, "SHARED")
      registration = registration_fixture(event_a)

      # Before the fix this raised (Repo.one with two matching rows) and
      # otherwise let a participant record attendance for event B.
      assert {:ok, :recorded} = Public.record_checkpoint_attendance(registration.id, "SHARED")

      records = Public.list_checkpoint_records(registration.id)
      assert [%{checkpoint_id: checkpoint_id}] = records
      assert checkpoint_id == checkpoint_a.id
    end

    test "rejects a code that only exists on another event" do
      event_a = event_fixture()
      event_b = event_fixture()
      _checkpoint_b = checkpoint_fixture(event_b, "ONLYB")
      registration = registration_fixture(event_a)

      assert {:error, :invalid_code} =
               Public.record_checkpoint_attendance(registration.id, "ONLYB")

      assert Public.list_checkpoint_records(registration.id) == []
    end

    test "rejects unknown codes" do
      event = event_fixture()
      registration = registration_fixture(event)

      assert {:error, :invalid_code} =
               Public.record_checkpoint_attendance(registration.id, "NOPE99")

      assert Public.list_checkpoint_records(registration.id) == []
    end

    test "rejects a code whose window has not opened yet" do
      event = event_fixture()
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      checkpoint_fixture(event, "FUTUR1", %{
        opens_at: DateTime.add(now, 3_600),
        closes_at: DateTime.add(now, 7_200)
      })

      registration = registration_fixture(event)

      assert {:error, :invalid_code} =
               Public.record_checkpoint_attendance(registration.id, "FUTUR1")

      assert Public.list_checkpoint_records(registration.id) == []
    end

    test "rejects a code whose window has closed" do
      event = event_fixture()
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      checkpoint_fixture(event, "CLOSED", %{
        opens_at: DateTime.add(now, -7_200),
        closes_at: DateTime.add(now, -3_600)
      })

      registration = registration_fixture(event)

      assert {:error, :invalid_code} =
               Public.record_checkpoint_attendance(registration.id, "CLOSED")

      assert Public.list_checkpoint_records(registration.id) == []
    end

    test "does not record the same checkpoint twice" do
      event = event_fixture()
      _checkpoint = checkpoint_fixture(event, "SESS02")
      registration = registration_fixture(event)

      assert {:ok, :recorded} = Public.record_checkpoint_attendance(registration.id, "SESS02")

      assert {:error, :already_recorded} =
               Public.record_checkpoint_attendance(registration.id, "SESS02")

      assert length(Public.list_checkpoint_records(registration.id)) == 1
    end

    test "rejects codes for a registration that does not exist" do
      assert {:error, :invalid_code} =
               Public.record_checkpoint_attendance(Ecto.UUID.generate(), "SESS01")
    end

    test "rate limits attempts per registration (brute-force protection)" do
      event = event_fixture()
      registration = registration_fixture(event)

      # 10 failed attempts are recorded, then the limiter kicks in.
      results =
        for _ <- 1..10, do: Public.record_checkpoint_attendance(registration.id, "WRONG")

      assert Enum.all?(results, &(&1 == {:error, :invalid_code}))

      assert {:error, :rate_limited} =
               Public.record_checkpoint_attendance(registration.id, "WRONG")

      # Even a valid code is blocked while the limit is active — the limiter
      # counts every attempt, valid or not.
      checkpoint_fixture(event, "SESS01")

      assert {:error, :rate_limited} =
               Public.record_checkpoint_attendance(registration.id, "SESS01")
    end
  end

  describe "list_checkpoint_records/1" do
    test "returns the registration's records ordered oldest first" do
      event = event_fixture()
      checkpoint_a = checkpoint_fixture(event, "FIRST1")
      checkpoint_b = checkpoint_fixture(event, "SECOND")
      registration = registration_fixture(event)

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      %EventCheckpointRecord{
        registration_id: registration.id,
        checkpoint_id: checkpoint_a.id,
        recorded_at: DateTime.add(now, -7_200)
      }
      |> Repo.insert!()

      %EventCheckpointRecord{
        registration_id: registration.id,
        checkpoint_id: checkpoint_b.id,
        recorded_at: DateTime.add(now, -3_600)
      }
      |> Repo.insert!()

      records = Public.list_checkpoint_records(registration.id)

      assert [%{checkpoint_id: first}, %{checkpoint_id: second}] = records
      assert first == checkpoint_a.id
      assert second == checkpoint_b.id
    end

    test "returns an empty list for a registration without records" do
      event = event_fixture()
      registration = registration_fixture(event)

      assert Public.list_checkpoint_records(registration.id) == []
    end
  end

  # --- Fixtures ---

  defp event_fixture(attrs \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %Curatorian.Public.Event{
      id: Ecto.UUID.generate(),
      host_user_id: Ecto.UUID.generate(),
      title: "Checkpoint Event #{System.unique_integer([:positive])}",
      slug: "checkpoint-event-#{System.unique_integer([:positive])}",
      event_type: :webinar,
      mode: :online,
      status: :published,
      starts_at: DateTime.add(now, 3_600),
      ends_at: DateTime.add(now, 7_200)
    }
    |> Map.merge(attrs)
    |> Repo.insert!()
  end

  defp registration_fixture(event, attrs \\ %{}) do
    %Curatorian.Public.EventRegistration{
      event_id: event.id,
      voile_user_id: Ecto.UUID.generate(),
      registration_code: "REG-" <> (:crypto.strong_rand_bytes(4) |> Base.encode16()),
      registered_at: DateTime.utc_now() |> DateTime.truncate(:second),
      status: :approved
    }
    |> Map.merge(attrs)
    |> Repo.insert!()
  end

  defp checkpoint_fixture(event, code, attrs \\ %{}) do
    %Curatorian.Public.EventCheckpoint{
      id: Ecto.UUID.generate(),
      event_id: event.id,
      code: code
    }
    |> Map.merge(attrs)
    |> Repo.insert!()
  end
end
