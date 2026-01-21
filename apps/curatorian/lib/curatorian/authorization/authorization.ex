defmodule Curatorian.Authorization do
  @moduledoc """
  The Authorization context for managing roles and permissions (RBAC).
  """

  import Ecto.Query, warn: false
  alias Curatorian.Repo

  alias Curatorian.Authorization.{Role, Permission, RolePermission}
  alias Curatorian.Accounts.User

  # ============================================================================
  # ROLES
  # ============================================================================

  @doc """
  Returns the list of roles.

  ## Examples

      iex> list_roles()
      [%Role{}, ...]

  """
  def list_roles do
    Role
    |> order_by([r], desc: r.priority, asc: r.name)
    |> Repo.all()
    |> Repo.preload(:permissions)
  end

  @doc """
  Returns the list of roles that are not system roles (can be managed by admins).
  """
  def list_manageable_roles do
    Role
    |> where([r], r.is_system_role == false)
    |> order_by([r], desc: r.priority, asc: r.name)
    |> Repo.all()
    |> Repo.preload(:permissions)
  end

  @doc """
  Gets a single role.

  Raises `Ecto.NoResultsError` if the Role does not exist.

  ## Examples

      iex> get_role!(123)
      %Role{}

      iex> get_role!(456)
      ** (Ecto.NoResultsError)

  """
  def get_role!(id) do
    Role
    |> Repo.get!(id)
    |> Repo.preload(:permissions)
  end

  @doc """
  Gets a role by slug.
  """
  def get_role_by_slug(slug) do
    Role
    |> Repo.get_by(slug: slug)
    |> Repo.preload(:permissions)
  end

  @doc """
  Creates a role.

  ## Examples

      iex> create_role(%{field: value})
      {:ok, %Role{}}

      iex> create_role(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_role(attrs \\ %{}) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a system role that cannot be edited by users.
  """
  def create_system_role(attrs \\ %{}) do
    %Role{}
    |> Role.system_role_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a role.

  ## Examples

      iex> update_role(role, %{field: new_value})
      {:ok, %Role{}}

      iex> update_role(role, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_role(%Role{} = role, attrs) do
    role
    |> Role.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a role. System roles cannot be deleted.

  ## Examples

      iex> delete_role(role)
      {:ok, %Role{}}

      iex> delete_role(role)
      {:error, %Ecto.Changeset{}}

  """
  def delete_role(%Role{is_system_role: true} = _role) do
    {:error, "Cannot delete system role"}
  end

  def delete_role(%Role{} = role) do
    Repo.delete(role)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking role changes.

  ## Examples

      iex> change_role(role)
      %Ecto.Changeset{data: %Role{}}

  """
  def change_role(%Role{} = role, attrs \\ %{}) do
    Role.changeset(role, attrs)
  end

  # ============================================================================
  # PERMISSIONS
  # ============================================================================

  @doc """
  Returns the list of permissions.

  ## Examples

      iex> list_permissions()
      [%Permission{}, ...]

  """
  def list_permissions do
    Permission
    |> order_by([p], [p.resource, p.action])
    |> Repo.all()
  end

  @doc """
  Returns permissions grouped by resource.
  """
  def list_permissions_by_resource do
    permissions = list_permissions()
    Enum.group_by(permissions, & &1.resource)
  end

  @doc """
  Gets a single permission.

  Raises `Ecto.NoResultsError` if the Permission does not exist.

  ## Examples

      iex> get_permission!(123)
      %Permission{}

      iex> get_permission!(456)
      ** (Ecto.NoResultsError)

  """
  def get_permission!(id), do: Repo.get!(Permission, id)

  @doc """
  Gets a permission by slug.
  """
  def get_permission_by_slug(slug) do
    Repo.get_by(Permission, slug: slug)
  end

  @doc """
  Creates a permission.

  ## Examples

      iex> create_permission(%{field: value})
      {:ok, %Permission{}}

      iex> create_permission(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_permission(attrs \\ %{}) do
    %Permission{}
    |> Permission.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a permission.

  ## Examples

      iex> update_permission(permission, %{field: new_value})
      {:ok, %Permission{}}

      iex> update_permission(permission, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_permission(%Permission{} = permission, attrs) do
    permission
    |> Permission.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a permission.

  ## Examples

      iex> delete_permission(permission)
      {:ok, %Permission{}}

      iex> delete_permission(permission)
      {:error, %Ecto.Changeset{}}

  """
  def delete_permission(%Permission{} = permission) do
    Repo.delete(permission)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking permission changes.

  ## Examples

      iex> change_permission(permission)
      %Ecto.Changeset{data: %Permission{}}

  """
  def change_permission(%Permission{} = permission, attrs \\ %{}) do
    Permission.changeset(permission, attrs)
  end

  # ============================================================================
  # ROLE PERMISSIONS
  # ============================================================================

  @doc """
  Assigns a permission to a role.
  """
  def assign_permission_to_role(role_id, permission_id) do
    %RolePermission{}
    |> RolePermission.changeset(%{role_id: role_id, permission_id: permission_id})
    |> Repo.insert()
  end

  @doc """
  Removes a permission from a role.
  """
  def remove_permission_from_role(role_id, permission_id) do
    case Repo.get_by(RolePermission, role_id: role_id, permission_id: permission_id) do
      nil -> {:error, :not_found}
      role_permission -> Repo.delete(role_permission)
    end
  end

  @doc """
  Updates all permissions for a role at once.
  Removes old permissions and adds new ones.
  """
  def sync_role_permissions(role_id, permission_ids) do
    # Delete existing permissions
    from(rp in RolePermission, where: rp.role_id == ^role_id)
    |> Repo.delete_all()

    # Insert new permissions
    Enum.each(permission_ids, fn permission_id ->
      assign_permission_to_role(role_id, permission_id)
    end)

    {:ok, get_role!(role_id)}
  end

  @doc """
  Gets all permissions for a role.
  """
  def get_role_permissions(role_id) do
    from(p in Permission,
      join: rp in RolePermission,
      on: p.id == rp.permission_id,
      where: rp.role_id == ^role_id
    )
    |> Repo.all()
  end

  # ============================================================================
  # AUTHORIZATION CHECKS
  # ============================================================================

  @doc """
  Checks if a user has a specific permission.

  ## Examples

      iex> user_has_permission?(user, "blogs:create")
      true

      iex> user_has_permission?(user, "blogs:create")
      false

  """
  def user_has_permission?(%User{role: nil}, _permission_slug), do: false

  def user_has_permission?(%User{role: %Role{}} = user, permission_slug) do
    permission_slug in get_user_permission_slugs(user)
  end

  def user_has_permission?(%User{role_id: role_id} = _user, permission_slug)
      when not is_nil(role_id) do
    role = get_role!(role_id)
    permission_slug in Enum.map(role.permissions, & &1.slug)
  end

  def user_has_permission?(_user, _permission_slug), do: false

  @doc """
  Checks if a user can perform an action on a resource.

  ## Examples

      iex> user_can?(user, "blogs", "create")
      true

  """
  def user_can?(%User{} = user, resource, action) do
    permission_slug = "#{resource}:#{action}"
    user_has_permission?(user, permission_slug)
  end

  @doc """
  Gets all permission slugs for a user.
  """
  def get_user_permission_slugs(%User{role: nil}), do: []

  def get_user_permission_slugs(%User{role: %Role{permissions: permissions}}) do
    Enum.map(permissions, & &1.slug)
  end

  def get_user_permission_slugs(%User{role_id: role_id}) when not is_nil(role_id) do
    role = get_role!(role_id)
    Enum.map(role.permissions, & &1.slug)
  end

  def get_user_permission_slugs(_user), do: []

  @doc """
  Checks if a user has a role with a specific slug.

  ## Examples

      iex> user_has_role?(user, "super_admin")
      true

  """
  def user_has_role?(%User{role: %Role{slug: slug}}, role_slug), do: slug == role_slug
  def user_has_role?(_user, _role_slug), do: false

  @doc """
  Checks if a user is a super admin.
  Super admins have all permissions.
  """
  def is_super_admin?(%User{role: %Role{slug: "super_admin"}}), do: true
  def is_super_admin?(_user), do: false

  @doc """
  Checks if a user is a manager.
  """
  def is_manager?(%User{role: %Role{slug: slug}}) when slug in ["super_admin", "manager"],
    do: true

  def is_manager?(_user), do: false

  @doc """
  Gets the default role for new users.
  """
  def get_default_role do
    get_role_by_slug("user") || get_role_by_slug("curator")
  end
end
