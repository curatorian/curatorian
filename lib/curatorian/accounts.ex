defmodule Curatorian.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Curatorian.Repo

  alias Curatorian.Accounts.{Education, Follow, User, UserProfile, UserToken, UserNotifier}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email) |> Repo.preload(:profile)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email) |> Repo.preload(:profile)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id) |> Repo.preload(:profile)

  @doc """
  Gets a user profile by user_id.
  ## Examples
      iex> get_user_profile_by_user_id(123)
      %UserProfile{}

      iex> get_user_profile_by_user_id(456)
      ** (Ecto.NoResultsError)
  """
  def get_user_profile_by_user_id(user_id) do
    Repo.get_by!(UserProfile, user_id: user_id)
    |> Repo.preload(:educations)
  end

  @doc """
  Get user Educations list.
  Examples
      iex> get_user_educations(123)
      [%Education{}]
  """
  def get_user_educations(user_id) do
    Repo.all(from e in Education, where: e.user_profile_id == ^user_id)
  end

  @doc """
  Gets a user profile by the username.
  ## Examples
      iex> get_user_profile_by_username("username")
      %UserProfile{}

      iex> get_user_profile_by_username("unknown")
      nil
  """
  def get_user_profile_by_username(username) do
    User
    |> Repo.get_by(username: username)
    |> Repo.preload(profile: [:educations])
  end

  @doc """
  Get User by Email or Register it if it does not exist.
  """
  def get_user_by_email_or_register(
        %{"email" => email, "name" => name, "picture" => picture} = user
      )
      when is_map(user) do
    case Repo.get_by(User, email: email) do
      nil ->
        # user needs some password, lets generate it and not tell them.
        pw = :rand.bytes(30) |> Base.encode64(padding: false)
        username = String.split(email, "@") |> hd

        {:ok, user, _} =
          register_user(%{email: email, username: username, password: pw}, %{
            fullname: name,
            user_image: picture
          })

        user

      user ->
        user
    end
  end

  @doc """
  Gets all Curatorian users.

  ## Examples

      iex> list_all_curatorian()
      [%User{}, ...]
  """
  def list_all_curatorian(params) do
    page =
      case Map.get(params, "page") do
        nil -> 1
        value -> String.to_integer(value)
      end

    per_page = 12
    offset = (page - 1) * per_page

    curatorian_query =
      from c in User,
        order_by: [desc: c.inserted_at],
        limit: ^per_page,
        offset: ^offset

    curatorians =
      curatorian_query
      |> Repo.all()
      |> Repo.preload(:profile)

    total_count = Repo.aggregate(User, :count, :id)
    total_pages = div(total_count + per_page - 1, per_page)

    %{
      curatorians: curatorians,
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages
    }
  end

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(user_attrs, profile_attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, User.registration_changeset(%User{}, user_attrs))
    |> Ecto.Multi.insert(:user_profile, fn %{user: user} ->
      # Ensure user_id is set and add more metadata from the google profile
      %{fullname: fullname, user_image: user_image} = profile_attrs

      UserProfile.changeset(%UserProfile{}, %{
        user_id: user.id,
        fullname: fullname,
        user_image: user_image
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user, user_profile: user_profile}} ->
        # Return both user and user_profile if needed
        {:ok, user, user_profile}

      {:error, :user, changeset, _} ->
        # Return the user changeset in case of user insertion error
        {:error, :user, changeset}

      {:error, :user_profile, changeset, _} ->
        # Return the user profile changeset in case of user profile insertion error
        {:error, :user_profile, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query) |> Repo.preload(:profile)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Changeset for User Profile
  """
  def change_user_profile(user_profile, attrs \\ %{}) do
    UserProfile.changeset(user_profile, attrs)
  end

  @doc """
  Update User Profile.
  """
  def update_user_profile(user, attrs) do
    user_profile = get_user_profile_by_user_id(user.id)

    user_profile
    |> UserProfile.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Changeset for Education
  """
  def change_education(education, attrs \\ %{}) do
    Education.changeset(education, attrs)
  end

  def get_education(education_id) do
    Repo.get(Education, education_id)
  end

  def delete_education(education_id) do
    education = Repo.get!(Education, education_id)
    Repo.delete(education)
  end

  @doc """
  Follow a User
  """
  def follow_user(follower_id, followed_id) when follower_id != followed_id do
    %Follow{}
    |> Follow.changeset(%{follower_id: follower_id, followed_id: followed_id})
    |> Repo.insert()
  end

  @doc """
  Unfollow a User
  """
  def unfollow_user(follower_id, followed_id) do
    case Repo.get(Follow, follower_id: follower_id, followed_id: followed_id) do
      nil -> {:error, "Not following user"}
      follow -> Repo.delete(follow)
    end
  end

  @doc """
  Get all following of a user
  """
  def list_following(%User{} = user) do
    user
    |> Repo.preload(:following)
    |> Map.get(:following)
  end

  @doc """
  Get all followers of a user
  """
  def list_followers(%User{} = user) do
    user
    |> Repo.preload(:followers)
    |> Map.get(:followers)
  end
end
