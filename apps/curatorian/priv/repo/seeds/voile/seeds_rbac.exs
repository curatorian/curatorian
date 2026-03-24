# Script for populating the database with RBAC data
# Run this with: mix run priv/repo/seeds_rbac.exs

alias Voile.Repo
alias VoileWeb.Auth.PermissionManager
alias Voile.Schema.Accounts.{Role, Permission}

IO.puts("🌱 Seeding RBAC data...")

# ============================================================================
# ROLES
# ============================================================================

IO.puts("📋 Creating roles...")

# Helper function to get or create role
get_or_create_role = fn attrs ->
  case Repo.get_by(Role, name: attrs.name) do
    nil ->
      {:ok, role} = PermissionManager.create_role(attrs)
      IO.puts("  ✓ Created: #{attrs.name}")
      role

    existing ->
      IO.puts("  ⤷ Exists: #{attrs.name}")
      existing
  end
end

# Super Admin - Has all permissions, can manage everything
super_admin = get_or_create_role.(%{
  name: "super_admin",
  description: "Full system access with all permissions",
  is_system_role: true
})

# Manager - Can manage users and content, but not system settings
manager = get_or_create_role.(%{
  name: "manager",
  description: "Can manage users, content, and moderate the platform"
})

# Curator - Can create and manage their own content
curator = get_or_create_role.(%{
  name: "curator",
  description: "Can create and curate collections, blogs, and manage their own content"
})

# User - Basic user with read access
user = get_or_create_role.(%{
  name: "user",
  description: "Basic user with read access and ability to comment"
})

# ============================================================================
# PERMISSIONS
# ============================================================================

IO.puts("\n🔐 Creating permissions...")

# Define all permissions
permissions_data = [
  # User Management
  %{
    name: "users.read",
    resource: "users",
    action: "read",
    description: "Can view user profiles and lists"
  },
  %{
    name: "users.create",
    resource: "users",
    action: "create",
    description: "Can create new user accounts"
  },
  %{
    name: "users.update",
    resource: "users",
    action: "update",
    description: "Can update user information and profiles"
  },
  %{
    name: "users.delete",
    resource: "users",
    action: "delete",
    description: "Can delete user accounts"
  },
  %{
    name: "users.manage",
    resource: "users",
    action: "manage",
    description: "Full user management access"
  },
  # Blog Management
  %{
    name: "blogs.read",
    resource: "blogs",
    action: "read",
    description: "Can view published blogs"
  },
  %{
    name: "blogs.create",
    resource: "blogs",
    action: "create",
    description: "Can create new blog posts"
  },
  %{
    name: "blogs.update",
    resource: "blogs",
    action: "update",
    description: "Can update own blog posts"
  },
  %{
    name: "blogs.delete",
    resource: "blogs",
    action: "delete",
    description: "Can delete own blog posts"
  },
  %{
    name: "blogs.publish",
    resource: "blogs",
    action: "publish",
    description: "Can publish and unpublish blog posts"
  },
  %{
    name: "blogs.manage",
    resource: "blogs",
    action: "manage",
    description: "Can manage all blog posts including others'"
  },
  # Organization Management
  %{
    name: "organizations.read",
    resource: "organizations",
    action: "read",
    description: "Can view organizations"
  },
  %{
    name: "organizations.create",
    resource: "organizations",
    action: "create",
    description: "Can create new organizations"
  },
  %{
    name: "organizations.update",
    resource: "organizations",
    action: "update",
    description: "Can update organizations they own"
  },
  %{
    name: "organizations.delete",
    resource: "organizations",
    action: "delete",
    description: "Can delete organizations they own"
  },
  %{
    name: "organizations.manage",
    resource: "organizations",
    action: "manage",
    description: "Can manage all organizations"
  },
  # Comments
  %{
    name: "comments.read",
    resource: "comments",
    action: "read",
    description: "Can view comments"
  },
  %{
    name: "comments.create",
    resource: "comments",
    action: "create",
    description: "Can post comments"
  },
  %{
    name: "comments.update",
    resource: "comments",
    action: "update",
    description: "Can update own comments"
  },
  %{
    name: "comments.delete",
    resource: "comments",
    action: "delete",
    description: "Can delete own comments"
  },
  %{
    name: "comments.moderate",
    resource: "comments",
    action: "moderate",
    description: "Can moderate and delete any comments"
  },
  # Roles & Permissions (Admin only)
  %{
    name: "roles.read",
    resource: "roles",
    action: "read",
    description: "Can view roles and permissions"
  },
  %{
    name: "roles.manage",
    resource: "roles",
    action: "manage",
    description: "Can create, update, and delete roles"
  },
  %{
    name: "permissions.manage",
    resource: "permissions",
    action: "manage",
    description: "Can create, update, and delete permissions"
  },
  # Content Moderation
  %{
    name: "content.moderate",
    resource: "content",
    action: "moderate",
    description: "Can moderate all content on the platform"
  },
]

# Create all permissions
created_permissions =
  Enum.map(permissions_data, fn perm_data ->
    case Repo.get_by(Permission, name: perm_data.name) do
      nil ->
        {:ok, permission} = PermissionManager.create_permission(perm_data)
        IO.puts("  ✓ Created: #{permission.name}")
        permission

      existing ->
        IO.puts("  ⤷ Exists: #{existing.name}")
        existing
    end
  end)

# ============================================================================
# ASSIGN PERMISSIONS TO ROLES
# ============================================================================

IO.puts("\n🔗 Assigning permissions to roles...")

# Super Admin - All permissions
super_admin_permission_ids = Enum.map(created_permissions, & &1.id)
PermissionManager.set_role_permissions(super_admin.id, super_admin_permission_ids)
IO.puts("  ✓ Super Admin: #{length(super_admin_permission_ids)} permissions")

# Manager - Most permissions except system role management
manager_permissions =
  created_permissions
  |> Enum.reject(fn p ->
    p.name in ["roles.manage", "permissions.manage", "organizations.delete", "organizations.manage"]
  end)
  |> Enum.map(& &1.id)

PermissionManager.set_role_permissions(manager.id, manager_permissions)
IO.puts("  ✓ Manager: #{length(manager_permissions)} permissions")

# Curator - Content creation and management
curator_permission_slugs = [
  "users.read",
  "blogs.read",
  "blogs.create",
  "blogs.update",
  "blogs.delete",
  "blogs.publish",
  "organizations.read",
  "organizations.create",
  "organizations.update",
  "organizations.delete",
  "comments.read",
  "comments.create",
  "comments.update",
  "comments.delete"
]

curator_permissions =
  created_permissions
  |> Enum.filter(fn p -> p.name in curator_permission_slugs end)
  |> Enum.map(& &1.id)

PermissionManager.set_role_permissions(curator.id, curator_permissions)
IO.puts("  ✓ Curator: #{length(curator_permissions)} permissions")

# User - Basic read and comment
user_permission_slugs = [
  "users.read",
  "blogs.read",
  "organizations.read",
  "comments.read",
  "comments.create",
  "comments.update",
  "comments.delete"
]

user_permissions =
  created_permissions
  |> Enum.filter(fn p -> p.name in user_permission_slugs end)
  |> Enum.map(& &1.id)

PermissionManager.set_role_permissions(user.id, user_permissions)
IO.puts("  ✓ User: #{length(user_permissions)} permissions")

IO.puts("\n✅ RBAC seeding completed successfully!")
IO.puts("\n📊 Summary:")
IO.puts("   - 4 roles created")
IO.puts("   - #{length(created_permissions)} permissions created")
IO.puts("   - All permissions assigned to roles")
IO.puts("\n🔑 Default Roles:")
IO.puts("   - super_admin: Full system access")
IO.puts("   - manager: User and content management")
IO.puts("   - curator: Content creation and curation")
IO.puts("   - user: Basic read and comment access")
