defmodule Curatorian.AccountsFixtures do
  @moduledoc """
  Test helpers for creating user entities via the `Curatorian.Accounts` context.
  """

  alias Curatorian.Accounts
  def unique_user_email, do: "user#{System.unique_integer([:positive, :monotonic])}@example.com"

  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    email = unique_user_email()
    username = email |> String.split("@") |> hd()

    Enum.into(attrs, %{
      email: email,
      username: username,
      password: valid_user_password(),
      registration_date: Date.utc_today()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    # Mark email as confirmed so the user can log in immediately in tests
    {:ok, user} =
      Voile.Repo.get!(Voile.Schema.Accounts.User, user.id)
      |> Ecto.Changeset.change(confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second))
      |> Voile.Repo.update()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
