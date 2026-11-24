defmodule Curatorian.Public.EventRegistrationTest do
  @moduledoc """
  Public event registration guards.

  Spec §4.2/§Security: the public registration is rate limited. In this
  implementation registration requires a Curatorian account, so the limit is
  per registrant.
  """

  use Curatorian.DataCase, async: true

  alias Curatorian.Public

  describe "register_for_event/3" do
    test "registers an approved participant when approval is not required" do
      event = event_fixture()
      user_id = Ecto.UUID.generate()

      assert {:ok, registration} =
               Public.register_for_event(user_id, event.id, requires_approval: false)

      assert registration.status == :approved
      assert registration.event_id == event.id
      # The participant page (/r/:token) depends on this.
      assert registration.token
      assert registration.consented_at
    end

    test "starts paid-event registrations as pending — payment is the approval gate" do
      # Previously a paid event with `requires_approval: false` approved the
      # registration immediately: non-payers held seats and received
      # reminders and join links.
      event = event_fixture(%{is_paid: true, price_idr: 100_000})
      user_id = Ecto.UUID.generate()

      assert {:ok, registration} =
               Public.register_for_event(user_id, event.id, requires_approval: false)

      assert registration.status == :pending
      assert registration.paid_at == nil
      # Seat is held while awaiting payment.
      assert registration.token
    end

    test "rate limits registrations per user" do
      user_id = Ecto.UUID.generate()
      events = for _ <- 1..10, do: event_fixture()

      results =
        for event <- events,
            do: Public.register_for_event(user_id, event.id, requires_approval: false)

      assert Enum.all?(results, &match?({:ok, _}, &1))

      # The 11th registration inside the window is blocked — even for an
      # event the user never registered to.
      fresh_event = event_fixture()

      assert {:error, :rate_limited} =
               Public.register_for_event(user_id, fresh_event.id, requires_approval: false)
    end
  end

  # --- Fixtures ---

  defp event_fixture(attrs \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    base = %Curatorian.Public.Event{
      id: Ecto.UUID.generate(),
      host_user_id: Ecto.UUID.generate(),
      title: "Registration Event #{System.unique_integer([:positive])}",
      slug: "registration-event-#{System.unique_integer([:positive])}",
      event_type: :webinar,
      mode: :online,
      status: :published,
      starts_at: DateTime.add(now, 3_600),
      ends_at: DateTime.add(now, 7_200)
    }

    struct(base, attrs)
    |> Repo.insert!()
  end
end
