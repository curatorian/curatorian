defmodule Curatorian.Orgs do
  @moduledoc """
  The Orgs context.
  """

  import Ecto.Query, warn: false
  alias Curatorian.Repo

  alias Curatorian.Orgs.Organization

  @doc """
  Returns the list of organizations.

  ## Examples

      iex> list_organizations()
      [%Organization{}, ...]

  """
  def list_organizations do
    Repo.all(Organization)
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
  def get_organization!(id), do: Repo.get!(Organization, id)

  @doc """
  Creates a organization.

  ## Examples

      iex> create_organization(%{field: value})
      {:ok, %Organization{}}

      iex> create_organization(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_organization(attrs \\ %{}) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
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
