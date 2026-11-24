defmodule Curatorian.AtriumProfileSync do
  @moduledoc """
  Provisions a user's matching `atrium.user_profiles` row as soon as they
  register or log in, instead of waiting for their first Atrium request.

  Atrium owns the profile table, so the provisioning call goes through its
  internal API (`POST /api/internal/profiles`), which rebuilds the profile
  from the authoritative Voile record (username, fullname, avatar, node).

  The call is fire-and-forget: registration and login must succeed even when
  Atrium is unreachable or the internal API key is not configured. Atrium's
  own lazy sync remains as a safety net.
  """

  alias Curatorian.EventPayments

  @doc """
  Enqueues a best-effort profile provision for the given Voile user id.

  Returns `:ok` immediately; the HTTP request runs in an unlinked task.
  """
  def enqueue(user_id) when is_binary(user_id) do
    Task.start(fn ->
      _ = EventPayments.sync_profile(user_id, nil, nil)
      :ok
    end)

    :ok
  end

  def enqueue(_user_id), do: :ok
end
