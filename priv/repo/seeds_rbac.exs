# Script for populating the database with RBAC data
# Run this with: mix run priv/repo/seeds_rbac.exs

alias Curatorian.Repo
alias Curatorian.Authorization
alias Curatorian.Authorization.{Role, Permission}

import Ecto.Query

IO.puts("🌱 Seeding RBAC data...")

# ============================================================================
# ROLES
# ============================================================================

IO.puts("📋 Creating roles...")

# Helper function to get or create role
get_or_create_role = fn attrs ->
  case Repo.get_by(Role, slug: attrs.slug) do
    nil ->
      {:ok, role} =
        if attrs[:is_system_role] do
          Authorization.create_system_role(attrs)
        else
          Authorization.create_role(attrs)
        end
      IO.puts("  ✓ Created: #{attrs.name}")
      role

    existing ->
      IO.puts("  ⤷ Exists: #{attrs.name}")
      existing
  end
end

# Super Admin - Has all permissions, can manage everything
super_admin = get_or_create_role.(%{
  name: "Super Admin",
  slug: "super_admin",
  description: "Full system access with all permissions",
  priority: 100,
  is_system_role: true
})

# Manager - Can manage users and content, but not system settings
manager = get_or_create_role.(%{
  name: "Manager",
  slug: "manager",
  description: "Can manage users, content, and moderate the platform",
  priority: 80
})

# Curator - Can create and manage their own content
curator = get_or_create_role.(%{
  name: "Curator",
  slug: "curator",
  description: "Can create and curate collections, blogs, and manage their own content",
  priority: 50
})

# User - Basic user with read access
user = get_or_create_role.(%{
  name: "User",
  slug: "user",
  description: "Basic user with read access and ability to comment",
  priority: 10
})

# ============================================================================
# PERMISSIONS
# ============================================================================

IO.puts("\n🔐 Creating permissions...")

# Define all permissions
permissions_data = [
  # User Management
  %{
    name: "View Users",
    slug: "users:read",
    resource: "users",
    action: "read",
    description: "Can view user profiles and lists"
  },
  %{
    name: "Create Users",
    slug: "users:create",
    resource: "users",
    action: "create",
    description: "Can create new user accounts"
  },
  %{
    name: "Update Users",
    slug: "users:update",
    resource: "users",
    action: "update",
    description: "Can update user information and profiles"
  },
  %{
    name: "Delete Users",
    slug: "users:delete",
    resource: "users",
    action: "delete",
    description: "Can delete user accounts"
  },
  %{
    name: "Manage Users",
    slug: "users:manage",
    resource: "users",
    action: "manage",
    description: "Full user management access"
  },
  # Blog Management
  %{
    name: "View Blogs",
    slug: "blogs:read",
    resource: "blogs",
    action: "read",
    description: "Can view published blogs"
  },
  %{
    name: "Create Blogs",
    slug: "blogs:create",
    resource: "blogs",
    action: "create",
    description: "Can create new blog posts"
  },
  %{
    name: "Update Blogs",
    slug: "blogs:update",
    resource: "blogs",
    action: "update",
    description: "Can update own blog posts"
  },
  %{
    name: "Delete Blogs",
    slug: "blogs:delete",
    resource: "blogs",
    action: "delete",
    description: "Can delete own blog posts"
  },
  %{
    name: "Publish Blogs",
    slug: "blogs:publish",
    resource: "blogs",
    action: "publish",
    description: "Can publish and unpublish blog posts"
  },
  %{
    name: "Manage All Blogs",
    slug: "blogs:manage",
    resource: "blogs",
    action: "manage",
    description: "Can manage all blog posts including others'"
  },
  # Organization Management
  %{
    name: "View Organizations",
    slug: "organizations:read",
    resource: "organizations",
    action: "read",
    description: "Can view organizations"
  },
  %{
    name: "Create Organizations",
    slug: "organizations:create",
    resource: "organizations",
    action: "create",
    description: "Can create new organizations"
  },
  %{
    name: "Update Organizations",
    slug: "organizations:update",
    resource: "organizations",
    action: "update",
    description: "Can update organizations they own"
  },
  %{
    name: "Delete Organizations",
    slug: "organizations:delete",
    resource: "organizations",
    action: "delete",
    description: "Can delete organizations they own"
  },
  %{
    name: "Manage All Organizations",
    slug: "organizations:manage",
    resource: "organizations",
    action: "manage",
    description: "Can manage all organizations"
  },
  # Comments
  %{
    name: "View Comments",
    slug: "comments:read",
    resource: "comments",
    action: "read",
    description: "Can view comments"
  },
  %{
    name: "Create Comments",
    slug: "comments:create",
    resource: "comments",
    action: "create",
    description: "Can post comments"
  },
  %{
    name: "Update Comments",
    slug: "comments:update",
    resource: "comments",
    action: "update",
    description: "Can update own comments"
  },
  %{
    name: "Delete Comments",
    slug: "comments:delete",
    resource: "comments",
    action: "delete",
    description: "Can delete own comments"
  },
  %{
    name: "Moderate Comments",
    slug: "comments:moderate",
    resource: "comments",
    action: "moderate",
    description: "Can moderate and delete any comments"
  },
  # Roles & Permissions (Admin only)
  %{
    name: "View Roles",
    slug: "roles:read",
    resource: "roles",
    action: "read",
    description: "Can view roles and permissions"
  },
  %{
    name: "Manage Roles",
    slug: "roles:manage",
    resource: "roles",
    action: "manage",
    description: "Can create, update, and delete roles"
  },
  %{
    name: "Manage Permissions",
    slug: "permissions:manage",
    resource: "permissions",
    action: "manage",
    description: "Can create, update, and delete permissions"
  },
  # Content Moderation
  %{
    name: "Moderate Content",
    slug: "content:moderate",
    resource: "content",
    action: "moderate",
    description: "Can moderate all content on the platform"
  }
]

# Create all permissions
created_permissions =
  Enum.map(permissions_data, fn perm_data ->
    case Repo.get_by(Permission, slug: perm_data.slug) do
      nil ->
        {:ok, permission} = Authorization.create_permission(perm_data)
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
Authorization.sync_role_permissions(super_admin.id, super_admin_permission_ids)
IO.puts("  ✓ Super Admin: #{length(super_admin_permission_ids)} permissions")

# Manager - Most permissions except system role management
manager_permissions =
  created_permissions
  |> Enum.reject(fn p ->
    p.slug in ["roles:manage", "permissions:manage"]
  end)
  |> Enum.map(& &1.id)

Authorization.sync_role_permissions(manager.id, manager_permissions)
IO.puts("  ✓ Manager: #{length(manager_permissions)} permissions")

# Curator - Content creation and management
curator_permission_slugs = [
  "users:read",
  "blogs:read",
  "blogs:create",
  "blogs:update",
  "blogs:delete",
  "blogs:publish",
  "organizations:read",
  "organizations:create",
  "organizations:update",
  "organizations:delete",
  "comments:read",
  "comments:create",
  "comments:update",
  "comments:delete"
]

curator_permissions =
  created_permissions
  |> Enum.filter(fn p -> p.slug in curator_permission_slugs end)
  |> Enum.map(& &1.id)

Authorization.sync_role_permissions(curator.id, curator_permissions)
IO.puts("  ✓ Curator: #{length(curator_permissions)} permissions")

# User - Basic read and comment
user_permission_slugs = [
  "users:read",
  "blogs:read",
  "organizations:read",
  "comments:read",
  "comments:create",
  "comments:update",
  "comments:delete"
]

user_permissions =
  created_permissions
  |> Enum.filter(fn p -> p.slug in user_permission_slugs end)
  |> Enum.map(& &1.id)

Authorization.sync_role_permissions(user.id, user_permissions)
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
