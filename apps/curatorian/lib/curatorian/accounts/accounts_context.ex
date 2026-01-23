defmodule Curatorian.Accounts do
  @moduledoc """
  The Accounts context.
  """

  # Delegate most functions to Voile.Schema.Accounts
  defdelegate get_user_by_email(email), to: Voile.Schema.Accounts
  defdelegate get_user_by_email_and_password(email, password), to: Voile.Schema.Accounts
  defdelegate get_user_by_login_and_password(login, password), to: Voile.Schema.Accounts
  defdelegate get_user_by_identifier(identifier), to: Voile.Schema.Accounts
  defdelegate list_users(), to: Voile.Schema.Accounts
  defdelegate list_users_paginated(page, per_page, filters), to: Voile.Schema.Accounts
  defdelegate get_user_with_associations_by_identifier(identifier), to: Voile.Schema.Accounts
  defdelegate get_user!(id), to: Voile.Schema.Accounts
  defdelegate get_user(id), to: Voile.Schema.Accounts
  defdelegate create_user(attrs), to: Voile.Schema.Accounts
  defdelegate delete_user(user), to: Voile.Schema.Accounts
  defdelegate change_user(user, attrs), to: Voile.Schema.Accounts
  defdelegate change_user_onboarding(user, attrs), to: Voile.Schema.Accounts
  defdelegate update_user(user, attrs), to: Voile.Schema.Accounts
  defdelegate update_user_onboarding(user, attrs), to: Voile.Schema.Accounts
  defdelegate update_profile_user(user, attrs), to: Voile.Schema.Accounts
  defdelegate admin_update_user(user, attrs), to: Voile.Schema.Accounts
  defdelegate admin_update_user_password(user, attrs), to: Voile.Schema.Accounts
  defdelegate update_user_login(user, attrs), to: Voile.Schema.Accounts
  defdelegate register_user(attrs), to: Voile.Schema.Accounts
  defdelegate sudo_mode?(user, minutes), to: Voile.Schema.Accounts
  defdelegate sudo_mode?(user), to: Voile.Schema.Accounts
  defdelegate change_user_registration(user, attrs), to: Voile.Schema.Accounts
  defdelegate change_user_email(user, attrs), to: Voile.Schema.Accounts
  defdelegate apply_user_email(user, password, attrs), to: Voile.Schema.Accounts
  defdelegate update_user_email(user, token), to: Voile.Schema.Accounts

  defdelegate deliver_user_update_email_instructions(user, current_email, update_email_url_fun),
    to: Voile.Schema.Accounts

  defdelegate change_user_password(user, attrs), to: Voile.Schema.Accounts
  defdelegate update_user_password(user, password, attrs), to: Voile.Schema.Accounts
  defdelegate has_password?(user), to: Voile.Schema.Accounts
  defdelegate generate_user_session_token(user), to: Voile.Schema.Accounts
  defdelegate get_user_by_session_token(token), to: Voile.Schema.Accounts
  defdelegate delete_user_session_token(token), to: Voile.Schema.Accounts
  defdelegate get_user_by_magic_link_token(token), to: Voile.Schema.Accounts
  defdelegate login_user_by_magic_link(token), to: Voile.Schema.Accounts
  defdelegate deliver_login_instructions(user, magic_link_url_fun), to: Voile.Schema.Accounts

  defdelegate deliver_user_confirmation_instructions(user, confirmation_url_fun),
    to: Voile.Schema.Accounts

  defdelegate get_user_by_confirmation_token(token), to: Voile.Schema.Accounts
  defdelegate confirm_user(token), to: Voile.Schema.Accounts

  defdelegate deliver_user_reset_password_instructions(user, reset_password_url_fun),
    to: Voile.Schema.Accounts

  defdelegate get_user_by_reset_password_token(token), to: Voile.Schema.Accounts
  defdelegate reset_user_password(user, attrs), to: Voile.Schema.Accounts
  defdelegate get_user_statistics(), to: Voile.Schema.Accounts
  defdelegate search_users(params), to: Voile.Schema.Accounts
  defdelegate search_users_paginated(page, per_page, params), to: Voile.Schema.Accounts
  defdelegate primary_role(user), to: Voile.Schema.Accounts
  defdelegate suspend_user(user, attrs), to: Voile.Schema.Accounts
  defdelegate unsuspend_user(user), to: Voile.Schema.Accounts
  defdelegate is_manually_suspended?(user), to: Voile.Schema.Accounts
  defdelegate lift_expired_suspensions(), to: Voile.Schema.Accounts

  alias Curatorian.Repo
  alias Curatorian.Accounts.Follow

  def list_follows do
    Repo.all(Follow)
  end

  def get_follow!(id) do
    Repo.get!(Follow, id)
  end

  def create_follow(attrs \\ %{}) do
    %Follow{}
    |> Follow.changeset(attrs)
    |> Repo.insert()
  end

  def update_follow(%Follow{} = follow, attrs) do
    follow
    |> Follow.changeset(attrs)
    |> Repo.update()
  end

  def delete_follow(%Follow{} = follow) do
    Repo.delete(follow)
  end

  def change_follow(%Follow{} = follow, attrs \\ %{}) do
    Follow.changeset(follow, attrs)
  end

  def follow_user(attrs, opts \\ []) do
    follower_id = opts[:follower_id] || attrs[:follower_id]
    followed_id = opts[:followed_id] || attrs[:followed_id]
    create_follow(%{follower_id: follower_id, followed_id: followed_id})
  end
end
