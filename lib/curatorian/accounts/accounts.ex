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
    case Repo.get_by(UserProfile, user_id: user_id) do
      nil ->
        %UserProfile{}
        |> UserProfile.changeset(%{user_id: user_id})
        |> Repo.insert!()

      profile ->
        profile
    end
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
  Update the user Login Infor with their Last Login Date and IP

  ## Examples
    iex> update_user_login_info(id, attrs)
    {:ok, %User{}}
    iex> update_user_login_info(id, %{})
    {:error, %Ecto.Changeset{}}
  """
  def update_user_login_info(id, attrs) do
    user = Repo.get!(User, id)

    user
    |> Ecto.Changeset.change(attrs)
    |> Repo.update()
  end

  @doc """
  Count all registered users
  """
  def count_users do
    from(u in User)
    |> Repo.aggregate(:count, :id)
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
        join: p in assoc(c, :profile),
        order_by: [desc: c.inserted_at],
        limit: ^per_page,
        offset: ^offset,
        select: c

    curatorians =
      curatorian_query
      |> Repo.all()
      |> Repo.preload(:profile)

    total_query = from c in User, join: p in assoc(c, :profile), select: count(c.id)
    total_count = Repo.one(total_query)
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
  @dialyzer {:nowarn_function, register_user: 2}
  def register_user(user_attrs, profile_attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, User.registration_changeset(%User{}, user_attrs))
    |> Ecto.Multi.insert(:user_profile, fn %{user: user} ->
      # Extract optional fields with defaults
      fullname = Map.get(profile_attrs, :fullname) || Map.get(profile_attrs, "fullname")
      user_image = Map.get(profile_attrs, :user_image) || Map.get(profile_attrs, "user_image")

      # Build profile params with only the required user_id
      profile_params = %{user_id: user.id}

      # Add optional fields only if they exist
      profile_params =
        if fullname, do: Map.put(profile_params, :fullname, fullname), else: profile_params

      profile_params =
        if user_image,
          do: Map.put(profile_params, :user_image, user_image),
          else: profile_params

      UserProfile.changeset(%UserProfile{}, profile_params)
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

  def register_user_by_email_only(attrs) do
    %User{}
    |> User.email_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @dialyzer {:nowarn_function, update_user_and_profile: 4}
  def update_user_and_profile(user, user_params, profile, profile_params) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.changeset(user, user_params))
    |> Ecto.Multi.update(:profile, UserProfile.changeset(profile, profile_params))
    |> Repo.transaction()
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

  See `Newver.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
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

  @dialyzer {:nowarn_function, user_email_multi: 3}
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
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
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

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transaction(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {user, tokens_to_expire}
      end
    end)
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
