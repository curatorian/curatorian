defmodule Curatorian.Orgs do
  @moduledoc """
  The Orgs context.
  """

  import Ecto.Query, warn: false
  alias Curatorian.Repo

  alias Curatorian.Orgs.{Organization, OrganizationRole, OrganizationUser}

  @doc """
  Returns the list of organizations.

  ## Examples

      iex> list_organizations()
      [%Organization{}, ...]

  """
  def list_organizations do
    Repo.all(Organization) |> Repo.preload([:owner, :organization_users])
  end

  @doc """
  Gets a single organization.

  Raises `Ecto.NoResultsError` if the Organization does not exist.

  ## Examples

      iex> get_organization!(123)
      %Organization{}

      iex> get_organization!(456)
      ** (Ecto.NoResultsError)

  """
  def get_organization!(id),
    do: Repo.get!(Organization, id) |> Repo.preload([:owner, :organization_users])

  @doc """
  Gets a single organization by slug.

  Raises `Ecto.NoResultsError` if the Organization does not exist.
  ## Examples

      iex> get_organization_by_slug("my-organization")
      %Organization{}

      iex> get_organization_by_slug("non-existent-slug")
      ** (Ecto.NoResultsError)
  """
  def get_organization_by_slug(slug) do
    Organization
    |> where([o], o.slug == ^slug)
    |> Repo.one!()
  end

  @doc """
  Creates a organization.

  ## Examples

      iex> create_organization(%{field: value})
      {:ok, %Organization{}}

      iex> create_organization(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_organization(owner, attrs) do
    # Create organization and set owner as admin
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:organization, Organization.changeset(%Organization{}, attrs))
    |> Ecto.Multi.run(:owner_membership, fn _repo, %{organization: org} ->
      add_member(org, owner, "owner")
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{organization: org}} -> {:ok, org}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Updates a organization.

  ## Examples

      iex> update_organization(organization, %{field: new_value})
      {:ok, %Organization{}}

      iex> update_organization(organization, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_organization(%Organization{} = organization, attrs) do
    organization
    |> Organization.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a organization.

  ## Examples

      iex> delete_organization(organization)
      {:ok, %Organization{}}

      iex> delete_organization(organization)
      {:error, %Ecto.Changeset{}}

  """
  def delete_organization(%Organization{} = organization) do
    Repo.delete(organization)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organization changes.

  ## Examples

      iex> change_organization(organization)
      %Ecto.Changeset{data: %Organization{}}

  """
  def change_organization(%Organization{} = organization, attrs \\ %{}) do
    Organization.changeset(organization, attrs)
  end

  def add_member(organization, user, role_slug) do
    role = Repo.get_by!(OrganizationRole, slug: role_slug)

    %OrganizationUser{}
    |> OrganizationUser.changeset(%{
      organization_id: organization.id,
      user_id: user.id,
      organization_role_id: role.id,
      joined_at: DateTime.utc_now()
    })
    |> Repo.insert()
  end

  def remove_member(organization, user) do
    Repo.delete_all(
      from ou in OrganizationUser,
        where: ou.organization_id == ^organization.id and ou.user_id == ^user.id
    )
  end

  # Permissions
  def has_permission?(org, user, required_permission) do
    user_role = get_user_role(org, user)
    permissions = role_permissions()[user_role] || []
    :manage_all in permissions or required_permission in permissions
  end

  def get_user_role(org, user) do
    case Repo.get_by(OrganizationUser, organization_id: org.id, user_id: user.id) do
      nil ->
        :guest

      membership ->
        membership
        |> Repo.preload(:organization_role)
        |> Map.get(:organization_role)
        |> Map.get(:slug)
    end
  end

  defp role_permissions do
    %{
      "owner" => [:manage_all],
      "admin" => [:manage_members, :create_content, :manage_events],
      "editor" => [:create_content, :edit_content],
      "member" => [:view_private, :comment],
      "guest" => [:view_public]
    }
  end

  alias Curatorian.Orgs.OrganizationRole

  @doc """
  Returns the list of organization_roles.

  ## Examples

      iex> list_organization_roles()
      [%OrganizationRole{}, ...]

  """
  def list_organization_roles do
    Repo.all(OrganizationRole)
  end

  @doc """
  Gets a single organization_role.

  Raises `Ecto.NoResultsError` if the Organization role does not exist.

  ## Examples

      iex> get_organization_role!(123)
      %OrganizationRole{}

      iex> get_organization_role!(456)
      ** (Ecto.NoResultsError)

  """
  def get_organization_role!(id), do: Repo.get!(OrganizationRole, id)

  @doc """
  Creates a organization_role.

  ## Examples

      iex> create_organization_role(%{field: value})
      {:ok, %OrganizationRole{}}

      iex> create_organization_role(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_organization_role(attrs \\ %{}) do
    %OrganizationRole{}
    |> OrganizationRole.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a organization_role.

  ## Examples

      iex> update_organization_role(organization_role, %{field: new_value})
      {:ok, %OrganizationRole{}}

      iex> update_organization_role(organization_role, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_organization_role(%OrganizationRole{} = organization_role, attrs) do
    organization_role
    |> OrganizationRole.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a organization_role.

  ## Examples

      iex> delete_organization_role(organization_role)
      {:ok, %OrganizationRole{}}

      iex> delete_organization_role(organization_role)
      {:error, %Ecto.Changeset{}}

  """
  def delete_organization_role(%OrganizationRole{} = organization_role) do
    Repo.delete(organization_role)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organization_role changes.

  ## Examples

      iex> change_organization_role(organization_role)
      %Ecto.Changeset{data: %OrganizationRole{}}

  """
  def change_organization_role(%OrganizationRole{} = organization_role, attrs \\ %{}) do
    OrganizationRole.changeset(organization_role, attrs)
  end

  alias Curatorian.Orgs.OrganizationUser

  @doc """
  Returns the list of organization_users.

  ## Examples

      iex> list_organization_users()
      [%OrganizationUser{}, ...]

  """
  def list_organization_users do
    Repo.all(OrganizationUser)
  end

  @doc """
  Gets a single organization_user.

  Raises `Ecto.NoResultsError` if the Organization user does not exist.

  ## Examples

      iex> get_organization_user!(123)
      %OrganizationUser{}

      iex> get_organization_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_organization_user!(id), do: Repo.get!(OrganizationUser, id)

  @doc """
  Creates a organization_user.

  ## Examples

      iex> create_organization_user(%{field: value})
      {:ok, %OrganizationUser{}}

      iex> create_organization_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_organization_user(attrs \\ %{}) do
    %OrganizationUser{}
    |> OrganizationUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a organization_user.

  ## Examples

      iex> update_organization_user(organization_user, %{field: new_value})
      {:ok, %OrganizationUser{}}

      iex> update_organization_user(organization_user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_organization_user(%OrganizationUser{} = organization_user, attrs) do
    organization_user
    |> OrganizationUser.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a organization_user.

  ## Examples

      iex> delete_organization_user(organization_user)
      {:ok, %OrganizationUser{}}

      iex> delete_organization_user(organization_user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_organization_user(%OrganizationUser{} = organization_user) do
    Repo.delete(organization_user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organization_user changes.

  ## Examples

      iex> change_organization_user(organization_user)
      %Ecto.Changeset{data: %OrganizationUser{}}

  """
  def change_organization_user(%OrganizationUser{} = organization_user, attrs \\ %{}) do
    OrganizationUser.changeset(organization_user, attrs)
  end
end
