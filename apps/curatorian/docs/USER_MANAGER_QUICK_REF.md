# User Manager - Quick Reference

## Features At A Glance

### 🔍 Search & Filter

- **Search**: Type name, email, or username in search bar
- **Role Filter**: Dropdown to filter by Super Admin, Manager, Curator, User
- **Status Filter**: Active (30 days), Inactive, Verified
- **Clear**: Reset all filters with one click

### 👥 Bulk Actions

- **Select**: Check boxes next to users or use "Select All"
- **Action**: Click "Bulk Actions (X)" button
- **Assign Role**: Choose role and apply to all selected

### 🗑️ Delete User

- **Permission**: Super Admin only
- **Action**: Click trash icon → Confirm in modal
- **Safe**: Confirmation required, shows username

### 📊 Activity Status

- 🟢 **Active**: Logged in within 30 days
- ⚫ **Inactive**: 30+ days or never logged in
- ✓ **Verified**: Blue check badge

## Quick Access URLs

```
/dashboard/user_manager                     - User list
/dashboard/user_manager/:username           - View profile
/dashboard/user_manager/:username/edit      - Edit user
```

## Common Tasks

### Find All Inactive Managers

1. Role Filter → Manager
2. Status Filter → Inactive
3. Results show all inactive managers

### Bulk Assign Role to Multiple Users

1. Use search/filters to find target users
2. Check boxes for users to update
3. Click "Bulk Actions (X)"
4. Select new role
5. Click "Apply to Selected Users"

### Delete a User

1. Find user in list
2. Click trash icon
3. Confirm username in modal
4. Click "Delete User"

### Check User Activity

1. Go to user profile
2. See "Account Activity" section:
   - Last Login
   - Account Created
   - Last Updated

## Permissions

| Action       | Super Admin | Manager | Curator | User |
| ------------ | ----------- | ------- | ------- | ---- |
| View         | ✓           | ✓       | ✓       | ✗    |
| Edit         | ✓           | ✓       | ✗       | ✗    |
| Delete       | ✓           | ✗       | ✗       | ✗    |
| Bulk Actions | ✓           | ✓       | ✗       | ✗    |

## Keyboard Shortcuts

Currently none, but consider adding:

- `/` - Focus search
- `Ctrl+A` - Select all
- `Esc` - Clear filters/close modals

## Tips & Tricks

1. **Combine Filters**: Use search + role + status together
2. **Bookmark**: URL saves filter state for quick access
3. **Audit Trail**: Check last login to find inactive accounts
4. **Bulk Efficiency**: Filter first, then bulk select
5. **Dark Mode**: Toggle theme - all pages support it

## Troubleshooting

**No results found?**

- Check filters are correct
- Try clearing filters
- Verify search term spelling

**Bulk action not working?**

- Ensure users are selected (checkboxes)
- Verify role was selected in modal
- Check you have manager/admin permissions

**Can't delete user?**

- Only super admins can delete
- Check current role in profile

## For Developers

### Context Functions

```elixir
Accounts.list_all_curatorian(%{
  "page" => 1,
  "search" => "john",
  "role_filter" => "curator",
  "status_filter" => "active"
})

Accounts.bulk_update_user_roles(["id1", "id2"], "role_id")
Accounts.delete_user("user_id")
```

### Helper Functions

```elixir
is_user_active?(user)           # => true/false
format_last_login(datetime)     # => "2 days ago"
get_role_name(user)             # => "Manager"
```

## Status Indicators

| Indicator   | Meaning            | Calculation                 |
| ----------- | ------------------ | --------------------------- |
| 🟢 Active   | Recent activity    | last_login within 30 days   |
| ⚫ Inactive | No recent activity | last_login > 30 days or nil |
| ✓ Verified  | Account verified   | is_verified == true         |

## Documentation

- **Complete Guide**: `docs/USER_MANAGER_COMPLETE_GUIDE.md`
- **Implementation**: `docs/USER_MANAGER_ENHANCEMENT_SUMMARY.md`
- **RBAC Setup**: `docs/RBAC_SETUP_GUIDE.md`

## Version

**Current**: v1.1.0
**Features**: Search, Filters, Bulk Actions, Activity Tracking, Delete
**Last Updated**: January 2025
