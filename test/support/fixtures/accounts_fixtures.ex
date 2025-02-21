defmodule Curatorian.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Curatorian.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user, _user_profile} =
      attrs
      |> valid_user_attributes()
      |> Curatorian.Accounts.register_user(attrs)

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Generate a follow.
  """
  def follow_fixture(attrs \\ %{}) do
    {:ok, follow} =
      attrs
      |> Enum.into(%{
        follower_id: user_fixture().id,
        followed_id: user_fixture().id
      })
      |> Curatorian.Accounts.follow_user(
        follower_id: attrs.follower_id,
        followed_id: attrs.followed_id
      )

    follow
  end
end
