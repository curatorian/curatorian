# User Manager System Guide

## Overview

The User Manager system provides comprehensive tools for managing users, roles, and permissions in the Curatorian platform.

## Features

### 1. User List (Index)

- View all users with pagination
- Search users by name, email, or username
- Filter by role
- Quick actions: View, Edit

### 2. User Profile (Show)

- View detailed user information
- See assigned role and permissions
- View activity status
- Quick edit access

### 3. Edit User (Edit)

- Update personal information
- Assign roles (for managers/admins)
- Verify user accounts
- Update professional details

### 4. Role Management

- Super Admin: Full access to all user management features
- Manager: Can manage users and assign non-admin roles
- Curator: View-only access to user lists

## Access Control

The User Manager uses the RBAC system for authorization:

```elixir
# Router configuration
live_session :require_manager,
  on_mount: [
    {CuratorianWeb.UserAuth, :require_authenticated},
    {CuratorianWeb.Authorization, :require_manager}
  ] do
  scope "/dashboard/user_manager" do
    live "/", UserManagerLive.Index, :index
    live "/:username", UserManagerLive.Show, :show
    live "/:username/edit", UserManagerLive.Edit, :edit
  end
end
```

## Usage

### Accessing User Manager

Navigate to `/dashboard/user_manager` (requires manager role or higher)

### Editing a User

1. Go to User Manager
2. Click "View" on any user
3. Click "Edit Profile"
4. Update fields as needed
5. Click "Save Changes"

### Assigning Roles

Only Super Admins and Managers can assign roles:

1. Edit a user
2. Select role from dropdown
3. Save changes

The user will immediately have the permissions associated with their new role.

## Future Enhancements

- [ ] Bulk user actions
- [ ] Export user lists
- [ ] User activity logs
- [ ] Password reset by admin
- [ ] Account suspension
- [ ] Advanced filtering

## Technical Details

### Files Structure

```
lib/curatorian_web/live/dashboard_live/user_manager_live/
├── index.ex      # User list with search/filter
├── show.ex       # User profile view
└── edit.ex       # User editor with role assignment
```

### Key Functions

- `Accounts.list_all_curatorian/1` - List users with pagination
- `Accounts.get_user_profile_by_username/1` - Get user details
- `Accounts.update_user_and_profile/4` - Update user & profile
- `Authorization.list_roles/0` - Get available roles

## Best Practices

1. **Always verify permissions** before allowing role changes
2. **Log important changes** for audit trails
3. **Validate email uniqueness** when updating
4. **Preserve user data** when updating profiles
5. **Use transactions** for multi-table updates
