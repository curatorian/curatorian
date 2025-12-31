# User Manager System - Complete Guide

## Overview

The User Manager is a comprehensive system for managing Curatorian users, their profiles, roles, and permissions. It provides powerful tools for searching, filtering, bulk operations, and detailed user management.

## Key Features

### 1. Advanced Search & Filtering

- **Real-time Search**: Search users by name, email, or username with 300ms debounce
- **Role Filter**: Filter by Super Admin, Manager, Curator, or User roles
- **Status Filter**: Filter by Active (logged in within 30 days), Inactive, or Verified users
- **Combined Filters**: Use multiple filters simultaneously for precise results
- **Clear Filters**: One-click button to reset all filters
- **URL Persistence**: All filters preserved in URL for bookmarking and sharing

### 2. User Activity Tracking

- **Last Login Display**: Shows when users last logged in
  - "Today", "Yesterday", "X days ago", "X weeks ago", "X months ago"
- **Activity Indicators**:
  - 🟢 Green dot: Active (logged in within 30 days)
  - ⚫ Gray dot: Inactive (30+ days or never logged in)
  - ✓ Blue badge: Verified account
- **Account Timeline**: Creation date, last update, and activity history

### 3. Bulk Operations

- **Multi-Select**: Select individual users via checkboxes
- **Select All**: Toggle selection of all users on current page
- **Bulk Role Assignment**: Assign roles to multiple users at once
- **Selection Counter**: Shows number of selected users in real-time
- **Bulk Action Modal**: Intuitive interface for bulk operations

### 4. User Profile Management

- **Comprehensive View**: See all user details in organized sections
  - Profile header with avatar and status
  - Account activity metrics
  - Personal information
  - Professional details
- **Edit Capabilities**:
  - Update personal information
  - Assign roles (authorized users only)
  - Verify accounts
  - Update professional details

### 5. Safe User Deletion

- **Permission Protected**: Only super admins can delete users
- **Confirmation Modal**: Prevents accidental deletions
- **User Identification**: Shows username in confirmation dialog
- **Cascade Delete**: Automatically handles related data

### 6. Modern UI/UX

- **Dark Mode**: Full dark mode support across all pages
- **Responsive Design**: Works on mobile, tablet, and desktop
- **Loading States**: Visual feedback during operations
- **Toast Notifications**: Success/error messages for all actions
- **Heroicons**: Beautiful icons throughout the interface

## Access Control

### Permission Levels

| Feature       | Super Admin | Manager | Curator | User |
| ------------- | ----------- | ------- | ------- | ---- |
| View Users    | ✓           | ✓       | ✓       | ✗    |
| Search/Filter | ✓           | ✓       | ✓       | ✗    |
| View Profiles | ✓           | ✓       | ✓       | ✗    |
| Edit Users    | ✓           | ✓       | ✗       | ✗    |
| Assign Roles  | ✓           | ✓       | ✗       | ✗    |
| Delete Users  | ✓           | ✗       | ✗       | ✗    |
| Bulk Actions  | ✓           | ✓       | ✗       | ✗    |

### Route Protection

All user manager routes are protected:

```elixir
live_session :require_manager,
  on_mount: [
    {CuratorianWeb.UserAuth, :require_authenticated},
    {CuratorianWeb.Authorization, :require_manager}
  ]
```

## Usage Guide

### Searching Users

1. Navigate to `/dashboard/user_manager`
2. Use the search bar at the top
3. Type username (e.g., "@johndoe"), full name, or email
4. Results update automatically as you type

### Filtering Users

**By Role:**

1. Click the "All Roles" dropdown
2. Select Super Admin, Manager, Curator, or User
3. List updates immediately

**By Status:**

1. Click the "All Status" dropdown
2. Select Active, Inactive, or Verified
3. List filters automatically

**Clear All Filters:**

- Click "Clear Filters" button to reset everything

### Bulk Role Assignment

1. Check boxes next to users you want to update
2. Use header checkbox to select all on page
3. Click "Bulk Actions (X)" button
4. Select new role from dropdown
5. Click "Apply to Selected Users"
6. Confirmation message appears when complete

### Viewing User Profiles

1. Click eye icon in Actions column
2. View comprehensive user information:
   - **Header**: Avatar, name, role badge, activity status
   - **Activity**: Last login, account created, last updated
   - **Personal Info**: Email, phone, birthday, gender
   - **Professional**: Job title, account type
3. Click "Back" to return to list
4. Click "Edit Profile" to make changes

### Editing Users

1. From user list, click edit icon (pencil)
2. Or from profile page, click "Edit Profile"
3. **Personal Information Section**:
   - Update username, full name, email
   - Change phone number, birthday, gender
4. **Professional Information Section**:
   - Update job title and other details
5. **Role & Permissions Section** (Super Admin/Manager only):
   - Select new role from dropdown
   - View associated permissions
   - Toggle "Mark account as verified"
6. Click "Update User" to save

### Deleting Users

**⚠️ Super Admin Only**

1. Click trash icon in Actions column
2. Confirmation modal appears
3. Review username to confirm deletion
4. Click "Delete User" to confirm
5. Or "Cancel" to abort
6. Success message appears when complete

## Technical Documentation

### Database Schema

**users table:**

- `id`: Binary UUID primary key
- `username`: Unique username
- `email`: Unique email address
- `user_role`: Legacy role field
- `user_type`: Account type
- `role_id`: Foreign key to roles table
- `last_login`: Timestamp of last login
- `is_verified`: Boolean verification flag
- `inserted_at`, `updated_at`: Timestamps

**user_profiles table:**

- `id`: Binary UUID primary key
- `user_id`: Foreign key to users
- `fullname`: User's full name
- `user_image`: Avatar URL
- `phone_number`: Contact number
- `birthday`: Date of birth
- `gender`: Gender identity
- `job_title`: Professional title

**roles table:**

- `id`: Binary UUID primary key
- `name`: Role display name
- `slug`: URL-safe identifier
- `priority`: Hierarchy ordering
- `description`: Role description

### LiveView Architecture

**Index Page (`index.ex`):**

- Handles user listing, search, filters, pagination
- Manages bulk selection state
- Provides delete and bulk action modals
- Real-time UI updates via Phoenix.LiveView

**Show Page (`show.ex`):**

- Displays comprehensive user profile
- Shows activity metrics and status
- Provides navigation to edit page

**Edit Page (`edit.ex`):**

- Form for updating user information
- Role assignment for authorized users
- Validation and error handling
- Success/error flash messages

### Context Functions

**Accounts Context (`lib/curatorian/accounts/accounts.ex`):**

```elixir
# List users with search, filters, and pagination
list_all_curatorian(params) :: %{
  curatorians: [%User{}],
  page: integer(),
  per_page: integer(),
  total_users: integer(),
  total_pages: integer()
}

# Get user by username with preloaded associations
get_user_profile_by_username(username) :: %User{}

# Update user and profile in transaction
update_user_and_profile(user, user_attrs, profile_attrs)
  :: {:ok, %User{}} | {:error, %Ecto.Changeset{}}

# Bulk update user roles
bulk_update_user_roles(user_ids, role_id)
  :: {:ok, count} | {:error, reason}

# Delete user account
delete_user(user_id)
  :: {:ok, %User{}} | {:error, reason}
```

**Authorization Context (`lib/curatorian/authorization/authorization.ex`):**

```elixir
# Get all roles
list_roles() :: [%Role{}]

# Check user permission
user_has_permission?(user, permission) :: boolean()

# Check if super admin
is_super_admin?(user) :: boolean()

# Check if manager
is_manager?(user) :: boolean()
```

### Query Implementation

**Search Query:**

```elixir
from [c, p, r] in base_query,
  where:
    ilike(c.username, ^search_term) or
    ilike(c.email, ^search_term) or
    ilike(p.fullname, ^search_term)
```

**Role Filter:**

```elixir
from [c, p, r] in query,
  where: r.slug == ^role_filter
```

**Status Filters:**

- Active: `c.last_login >= thirty_days_ago`
- Inactive: `is_nil(c.last_login) or c.last_login < thirty_days_ago`
- Verified: `c.is_verified == true`

### Activity Status Logic

```elixir
defp is_user_active?(user) do
  if user.last_login do
    days_since_login = DateTime.diff(DateTime.utc_now(), user.last_login, :day)
    days_since_login <= 30
  else
    false
  end
end
```

### Pagination

- **Per Page**: 12 users (configurable)
- **URL Format**: `/dashboard/user_manager?page=2&search=john&role_filter=curator`
- **Navigation**: Previous/Next buttons with page counter
- **Empty States**: Friendly message when no results

## Best Practices

### Security

1. **Always verify role changes** before saving
2. **Use confirmation modals** for destructive actions
3. **Audit trail**: Log important role changes (future enhancement)
4. **Least privilege**: Assign minimum necessary role

### Performance

1. **Use search/filters** before bulk operations to reduce load
2. **Preload associations** to avoid N+1 queries
3. **Limit bulk operations** to reasonable batch sizes
4. **Index database fields** used in search (username, email)

### User Experience

1. **Search first**: Use search to find specific users
2. **Filter by role**: Quickly find users of specific role
3. **Bulk operations**: Efficient for updating multiple users
4. **Regular audits**: Review inactive users periodically

### Maintenance

1. **Monitor activity**: Track inactive users
2. **Clean up**: Remove or archive inactive accounts
3. **Role reviews**: Periodically audit role assignments
4. **Documentation**: Keep role definitions up to date

## UI Components Reference

### Headers

```heex
<.header>
  User Management
  <:subtitle>Manage users, roles, and permissions</:subtitle>
  <:actions>
    <.button phx-click="action">Action</.button>
  </:actions>
</.header>
```

### Search/Filter Form

```heex
<.input
  type="text"
  name="search"
  placeholder="Search..."
  phx-debounce="300"
/>
```

### Modal Dialogs

```heex
<.modal id="modal-id" show on_cancel={JS.push("cancel")}>
  <!-- Modal content -->
</.modal>
```

### Status Badges

```heex
<span class="flex items-center gap-1 text-sm">
  <span class="w-2 h-2 bg-green-500 rounded-full"></span>
  Active
</span>
```

### Dark Mode Classes

All components support dark mode via Tailwind's `dark:` prefix:

- `dark:bg-gray-800` - Dark backgrounds
- `dark:text-gray-100` - Dark text
- `dark:border-gray-700` - Dark borders

## Routes

| Path                                     | Action       | LiveView | Permission |
| ---------------------------------------- | ------------ | -------- | ---------- |
| `/dashboard/user_manager`                | List users   | Index    | Manager+   |
| `/dashboard/user_manager/:username`      | View profile | Show     | Manager+   |
| `/dashboard/user_manager/:username/edit` | Edit user    | Edit     | Manager+   |

## Future Enhancements

- [ ] Export users to CSV
- [ ] Email users directly from manager
- [ ] User activity logs
- [ ] Advanced filtering (creation date, etc.)
- [ ] User groups/teams
- [ ] Custom fields for profiles
- [ ] Import users from CSV
- [ ] User analytics dashboard

## Troubleshooting

### Users not appearing in search

- Check filter selections
- Verify search term spelling
- Clear filters and try again
- Check user exists in database

### Bulk actions not working

- Ensure users are selected (checkboxes checked)
- Verify you have manager/admin permissions
- Check that role was selected in modal
- Review browser console for errors

### Role assignment fails

- Confirm you have permission to assign roles
- Verify role exists in database
- Check for validation errors
- Ensure user account is active

### Activity status incorrect

- Verify `last_login` field is being updated
- Check timezone configuration
- Confirm DateTime calculations are correct
- Review 30-day threshold logic

## Support

For issues or questions:

1. Check this documentation first
2. Review error messages in browser console
3. Check Phoenix server logs
4. Verify database migrations are up to date
5. Contact development team

## Version History

- **v1.1.0** (Current): Added search, filters, bulk actions, activity tracking
- **v1.0.0**: Initial release with basic user management
