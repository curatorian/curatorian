# RBAC Quick Start Guide

## Setup (First Time)

### 1. Run Migration
```bash
mix ecto.migrate
```

### 2. Seed RBAC Data
```bash
mix run priv/repo/seeds_rbac.exs
```

This creates:
- ✅ 4 default roles (super_admin, manager, curator, user)
- ✅ 25 permissions across different resources
- ✅ Permission assignments for each role

### 3. Assign Super Admin Role to Your User

In IEx console:
```elixir
iex -S mix

# Get your user (replace with your actual user ID or email)
user = Curatorian.Accounts.get_user_by_email("your@email.com")

# Get super admin role
super_admin = Curatorian.Authorization.get_role_by_slug("super_admin")

# Assign role to user
{:ok, _user} = Curatorian.Accounts.update_user(user, %{role_id: super_admin.id})
```

## Managing Roles & Permissions

### Access Admin Panel

1. Login as super admin
2. Navigate to: `http://localhost:4000/dashboard/admin/roles`

### Create New Role

1. Click "New Role"
2. Fill in:
   - **Name**: Display name (e.g., "Content Manager")
   - **Slug**: Unique identifier (e.g., "content_manager")
   - **Description**: What this role does
   - **Priority**: Number (higher = more important)
3. Select permissions by checking boxes
4. Click "Save Role"

### Assign Role to User

In your user management interface or IEx:
```elixir
user = Curatorian.Accounts.get_user!(user_id)
role = Curatorian.Authorization.get_role_by_slug("curator")
Curatorian.Accounts.update_user(user, %{role_id: role.id})
```

## Using Permissions in Code

### In Templates (Most Common)

```heex
<%!-- Check if user can create blogs --%>
<%= if can?(@current_scope.user, "blogs:create") do %>
  <.link navigate={~p"/blogs/new"}>Create Blog</.link>
<% end %>

<%!-- Check if user is super admin --%>
<%= if is_super_admin?(@current_scope.user) do %>
  <.link navigate={~p"/dashboard/admin"}>Admin Panel</.link>
<% end %>

<%!-- Check if user is manager or super admin --%>
<%= if is_manager?(@current_scope.user) do %>
  <div>Manager Dashboard</div>
<% end %>
```

### In LiveViews (Route Protection)

```elixir
# In router.ex
live_session :require_blog_create,
  on_mount: [
    {CuratorianWeb.UserAuth, :require_authenticated},
    {CuratorianWeb.Authorization, {:require_permission, "blogs:create"}}
  ] do
  live "/blogs/new", BlogLive.New, :new
end
```

### In Context Functions

```elixir
def create_blog(user, attrs) do
  if Authorization.user_has_permission?(user, "blogs:create") do
    # Create blog logic
  else
    {:error, :unauthorized}
  end
end
```

## Default Role Hierarchy

1. **Super Admin** (Priority: 100)
   - Has ALL permissions
   - Can manage roles and permissions
   - Cannot be deleted

2. **Manager** (Priority: 80)
   - User management
   - Content management
   - Moderation
   - Cannot manage roles/permissions

3. **Curator** (Priority: 50)
   - Create blogs and organizations
   - Manage own content
   - Default role for new users

4. **User** (Priority: 10)
   - Read access
   - Can comment
   - Basic user level

## Common Tasks

### Add Permission to Existing Role

Via Admin Panel:
1. Go to `/dashboard/admin/roles`
2. Click "Edit" on the role
3. Check the new permission
4. Save

Via IEx:
```elixir
role = Authorization.get_role_by_slug("curator")
permission = Authorization.get_permission_by_slug("projects:create")
Authorization.assign_permission_to_role(role.id, permission.id)
```

### Create Custom Permission

Via Admin Panel:
1. Go to `/dashboard/admin/permissions`
2. Click "New Permission"
3. Fill in:
   - Name: "Create Projects"
   - Slug: "projects:create"
   - Resource: "projects"
   - Action: "create"
4. Save

### Check What Permissions a User Has

```elixir
user = Curatorian.Accounts.get_user!(id)
permissions = Authorization.get_user_permission_slugs(user)
IO.inspect(permissions)
```

## Migration from Old System

If you have existing users with old `user_role` field:

```elixir
# Run this once to migrate all users
alias Curatorian.{Repo, Accounts.User, Authorization}

roles = %{
  "super_admin" => Authorization.get_role_by_slug("super_admin"),
  "manager" => Authorization.get_role_by_slug("manager"),
  "curator" => Authorization.get_role_by_slug("curator")
}

default_role = Authorization.get_role_by_slug("user")

User
|> Repo.all()
|> Enum.each(fn user ->
  role = roles[user.user_role] || default_role
  if role do
    user
    |> Ecto.Changeset.change(%{role_id: role.id})
    |> Repo.update()
  end
end)
```

## Troubleshooting

### "No permission" error
- Verify user has a role assigned
- Check role has the required permission
- Ensure `current_scope.user` is available in template

### Can't access admin panel
- Verify user has `super_admin` role
- Check router has super admin routes configured
- Clear browser cache and re-login

### New users have no role
- Verify default role exists: `Authorization.get_default_role()`
- Check `Accounts.register_user/2` assigns role

### Permission not working
- Ensure permission slug is correct (check in DB or admin panel)
- Verify role has that permission assigned
- User must have role preloaded

## Next Steps

1. ✅ **Test the system**: Create test users with different roles
2. ✅ **Customize permissions**: Add permissions for your specific features
3. ✅ **Update existing code**: Replace old role checks with permission checks
4. ✅ **Document your permissions**: Keep track of custom permissions you create
5. ✅ **Regular audits**: Review role permissions periodically

## Resources

- Full Guide: [RBAC_GUIDE.md](RBAC_GUIDE.md)
- Default Permissions: See `priv/repo/seeds_rbac.exs`
- Authorization Module: `lib/curatorian/authorization/authorization.ex`

## Support

For issues or questions:
1. Check [RBAC_GUIDE.md](RBAC_GUIDE.md) for detailed documentation
2. Review the seed file for default setup
3. Inspect roles/permissions in admin panel
