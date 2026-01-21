# RBAC (Role-Based Access Control) System

## Overview

This document describes the comprehensive RBAC system implemented for the Curatorian project. The system provides flexible, granular permission management that can be fully controlled by super admins through the dashboard.

## Architecture

### Database Schema

The RBAC system consists of three main tables:

1. **roles** - Defines user roles
   - `id` (binary_id)
   - `name` - Display name
   - `slug` - Unique identifier (e.g., "super_admin")
   - `description` - Role description
   - `is_system_role` - Whether the role is protected from deletion
   - `priority` - Display priority (higher = more important)

2. **permissions** - Defines granular permissions
   - `id` (binary_id)
   - `name` - Display name
   - `slug` - Unique identifier (e.g., "blogs:create")
   - `resource` - The resource type (e.g., "blogs", "users")
   - `action` - The action type (create, read, update, delete, manage, publish, moderate)
   - `description` - Permission description

3. **role_permissions** - Many-to-many join table
   - Links roles to their permissions

4. **users** - Updated to include:
   - `role_id` - Foreign key to roles table

## Default Roles

The system comes with four default roles:

### 1. Super Admin (`super_admin`)
- **Priority**: 100
- **System Role**: Yes (cannot be deleted)
- **Permissions**: ALL
- **Purpose**: Full system access including role and permission management

### 2. Manager (`manager`)
- **Priority**: 80
- **Permissions**: 
  - All user management
  - All content management (blogs, organizations)
  - Content moderation
  - Comment moderation
- **Cannot**:
  - Manage roles or permissions
- **Purpose**: Platform administration and user management

### 3. Curator (`curator`)
- **Priority**: 50
- **Permissions**:
  - View users
  - Create, read, update, delete own blogs
  - Publish blogs
  - Create and manage organizations
  - Create and manage own comments
- **Purpose**: Content creators who curate collections and blogs

### 4. User (`user`)
- **Priority**: 10
- **Permissions**:
  - View users, blogs, organizations
  - Create, update, delete own comments
- **Purpose**: Basic platform users

## Permission Naming Convention

Permissions follow the pattern: `resource:action`

Examples:
- `blogs:create` - Can create blogs
- `users:manage` - Can fully manage users
- `comments:moderate` - Can moderate all comments

## Usage

### In LiveViews

#### Method 1: Using on_mount callbacks

```elixir
# Require specific permission
live_session :require_blog_create,
  on_mount: [
    {CuratorianWeb.UserAuth, :require_authenticated},
    {CuratorianWeb.Authorization, {:require_permission, "blogs:create"}}
  ] do
  live "/blogs/new", BlogLive.New, :new
end

# Require specific role
live_session :require_manager,
  on_mount: [
    {CuratorianWeb.UserAuth, :require_authenticated},
    {CuratorianWeb.Authorization, :require_manager}
  ] do
  live "/dashboard/users", UserManagerLive.Index, :index
end

# Require super admin
live_session :require_super_admin,
  on_mount: [
    {CuratorianWeb.UserAuth, :require_authenticated},
    {CuratorianWeb.Authorization, :require_super_admin}
  ] do
  live "/dashboard/admin/roles", RolesLive.Index, :index
end
```

#### Method 2: In templates

```elixir
# Check permission
<%= if CuratorianWeb.Authorization.can?(@current_scope.user, "blogs:create") do %>
  <.link navigate={~p"/blogs/new"}>Create Blog</.link>
<% end %>

# Check permission with resource and action
<%= if CuratorianWeb.Authorization.can?(@current_scope.user, "blogs", "delete") do %>
  <button>Delete</button>
<% end %>

# Check role
<%= if CuratorianWeb.Authorization.has_role?(@current_scope.user, "super_admin") do %>
  <.link navigate={~p"/dashboard/admin"}>Admin Panel</.link>
<% end %>

# Check if super admin
<%= if CuratorianWeb.Authorization.is_super_admin?(@current_scope.user) do %>
  <div>Super Admin Options</div>
<% end %>

# Check if manager
<%= if CuratorianWeb.Authorization.is_manager?(@current_scope.user) do %>
  <div>Manager Options</div>
<% end %>
```

### In Controllers

```elixir
# Using plugs
defmodule CuratorianWeb.BlogController do
  use CuratorianWeb, :controller

  # Require permission for specific actions
  plug CuratorianWeb.Authorization, {:require_permission, "blogs:create"} when action in [:new, :create]
  plug CuratorianWeb.Authorization, {:require_permission, "blogs:delete"} when action in [:delete]

  # Or require role
  plug CuratorianWeb.Authorization, :require_manager when action in [:index]
end
```

### In Context Functions

```elixir
alias Curatorian.Authorization

# Check if user has permission
if Authorization.user_has_permission?(user, "blogs:create") do
  create_blog(attrs)
else
  {:error, :unauthorized}
end

# Check if user can perform action on resource
if Authorization.user_can?(user, "blogs", "update") do
  update_blog(blog, attrs)
end

# Check role
if Authorization.user_has_role?(user, "super_admin") do
  # Super admin logic
end

# Check if super admin
if Authorization.is_super_admin?(user) do
  # Full access logic
end

# Check if manager
if Authorization.is_manager?(user) do
  # Manager logic
end
```

## Management Interface

### Accessing RBAC Management

Super admins can access RBAC management at:
- **Roles**: `/dashboard/admin/roles`
- **Permissions**: `/dashboard/admin/permissions`

### Managing Roles

1. **Create Role**:
   - Navigate to `/dashboard/admin/roles`
   - Click "New Role"
   - Fill in name, slug, description, priority
   - Select permissions
   - Save

2. **Edit Role**:
   - Click "Edit" next to any role
   - Modify details and permissions
   - Save changes

3. **Delete Role**:
   - Click "Delete" (only available for non-system roles)
   - Confirm deletion

### Managing Permissions

1. **Create Permission**:
   - Navigate to `/dashboard/admin/permissions`
   - Click "New Permission"
   - Fill in name, slug, resource, action, description
   - Save

2. **Edit/Delete Permission**:
   - Find the permission in its resource group
   - Click "Edit" or "Delete"

## Migration Guide

### Initial Setup

1. **Run the migration**:
   ```bash
   mix ecto.migrate
   ```

2. **Seed RBAC data**:
   ```bash
   mix run priv/repo/seeds_rbac.exs
   ```

3. **Assign initial super admin role**:
   ```elixir
   # In IEx or a script
   user = Curatorian.Accounts.get_user!(user_id)
   super_admin_role = Curatorian.Authorization.get_role_by_slug("super_admin")
   Curatorian.Accounts.update_user(user, %{role_id: super_admin_role.id})
   ```

### Migrating Existing Users

If you have existing users with the old `user_role` string field:

```elixir
# Migration script
alias Curatorian.Repo
alias Curatorian.Accounts.User
alias Curatorian.Authorization

# Get all roles
roles = %{
  "super_admin" => Authorization.get_role_by_slug("super_admin"),
  "manager" => Authorization.get_role_by_slug("manager"),
  "curator" => Authorization.get_role_by_slug("curator"),
  "user" => Authorization.get_role_by_slug("user")
}

# Update all users
User
|> Repo.all()
|> Enum.each(fn user ->
  role = roles[user.user_role] || roles["user"]
  user
  |> Ecto.Changeset.change(%{role_id: role.id})
  |> Repo.update()
end)
```

## Adding Custom Permissions

To add new permissions for new features:

1. **Via Seeds** (for initial setup):
   Edit `priv/repo/seeds_rbac.exs` and add to `permissions_data`

2. **Via Admin Interface** (recommended):
   - Login as super admin
   - Navigate to `/dashboard/admin/permissions`
   - Create new permission

3. **Via IEx**:
   ```elixir
   Curatorian.Authorization.create_permission(%{
     name: "Manage Projects",
     slug: "projects:manage",
     resource: "projects",
     action: "manage",
     description: "Can manage all projects"
   })
   ```

## Best Practices

1. **Use Specific Permissions**: Instead of checking roles, check permissions for more granular control
   
2. **System Roles**: Mark core roles as system roles to prevent accidental deletion

3. **Permission Naming**: Follow the `resource:action` convention consistently

4. **Default Role**: Always ensure a default role exists for new user registration

5. **Preload Roles**: Always preload the role when fetching users for permission checks:
   ```elixir
   user = Repo.get!(User, id) |> Repo.preload(:role)
   ```

6. **Testing**: Test authorization logic thoroughly, especially for edge cases

## API Reference

### Authorization Context

```elixir
# Roles
Authorization.list_roles()
Authorization.get_role!(id)
Authorization.get_role_by_slug(slug)
Authorization.create_role(attrs)
Authorization.update_role(role, attrs)
Authorization.delete_role(role)

# Permissions
Authorization.list_permissions()
Authorization.list_permissions_by_resource()
Authorization.create_permission(attrs)
Authorization.update_permission(permission, attrs)
Authorization.delete_permission(permission)

# Role Permissions
Authorization.assign_permission_to_role(role_id, permission_id)
Authorization.remove_permission_from_role(role_id, permission_id)
Authorization.sync_role_permissions(role_id, permission_ids)
Authorization.get_role_permissions(role_id)

# Authorization Checks
Authorization.user_has_permission?(user, permission_slug)
Authorization.user_can?(user, resource, action)
Authorization.user_has_role?(user, role_slug)
Authorization.is_super_admin?(user)
Authorization.is_manager?(user)
Authorization.get_user_permission_slugs(user)
```

## Troubleshooting

### User has no role
- Ensure default role exists: `Authorization.get_default_role()`
- Manually assign role: `Accounts.update_user(user, %{role_id: role.id})`

### Permission check failing
- Verify user has role preloaded: `user = Repo.preload(user, :role)`
- Check permission slug matches exactly
- Verify role has the permission assigned

### Cannot access admin panel
- Verify user has super_admin role
- Check router configuration
- Ensure `CuratorianWeb.Authorization` plug is properly imported

## Security Considerations

1. **Always validate authorization** server-side, never trust client-side checks alone
2. **System roles** cannot be deleted to prevent lockout
3. **Super admin role** should be assigned carefully
4. **Regular audits** of role permissions are recommended
5. **Log permission changes** for security auditing (future enhancement)
