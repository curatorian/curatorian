defmodule CuratorianWeb.DashboardLive.UserManagerLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <.header>
      User Profile
      <:actions>
        <.link navigate="/dashboard/user_manager" class="btn btn-secondary">
          <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back
        </.link>
      </:actions>
    </.header>

    <div class="space-y-6 mt-5">
      <%!-- Profile Header --%>
      <div class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow border border-gray-200 dark:border-gray-700">
        <div class="flex items-start justify-between">
          <div class="flex items-center gap-6">
            <%= if @user.profile.user_image do %>
              <img
                src={@user.profile.user_image}
                class="w-24 h-24 rounded-full"
                referrerPolicy="no-referrer"
              />
            <% else %>
              <div class="w-24 h-24 rounded-full bg-gray-300 dark:bg-gray-600 flex items-center justify-center">
                <span class="text-3xl text-gray-700 dark:text-gray-200 font-semibold">
                  {String.first(@user.profile.fullname || "?")}
                </span>
              </div>
            <% end %>
            
            <div>
              <h2 class="text-2xl font-bold dark:text-gray-100">{@user.profile.fullname}</h2>
              
              <p class="text-gray-500 dark:text-gray-400">@{@user.username}</p>
              
              <div class="flex items-center gap-3 mt-3">
                <span class={[
                  "px-3 py-1 text-xs font-semibold rounded-full",
                  get_role_badge_class(@user)
                ]}>
                  {get_role_name(@user)}
                </span>
                <%= if is_user_active?(@user) do %>
                  <span class="flex items-center gap-1 text-sm text-green-600 dark:text-green-400">
                    <span class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span> Active
                  </span>
                <% else %>
                  <span class="flex items-center gap-1 text-sm text-gray-400">
                    <span class="w-2 h-2 bg-gray-400 rounded-full"></span> Inactive
                  </span>
                <% end %>
                
                <%= if @user.is_verified do %>
                  <span class="flex items-center gap-1 text-sm text-blue-600 dark:text-blue-400">
                    <.icon name="hero-check-badge" class="w-5 h-5" /> Verified
                  </span>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
       <%!-- Activity Status --%>
      <div class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold mb-4 dark:text-gray-200">Account Activity</h3>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <p class="text-sm text-gray-500 dark:text-gray-400 mb-1">Last Login</p>
            
            <p class="text-lg font-medium dark:text-gray-200">
              <%= if @user.last_login do %>
                {format_datetime(@user.last_login)}
              <% else %>
                <span class="text-gray-400">Never</span>
              <% end %>
            </p>
            
            <%= if @user.last_login do %>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                {format_last_login(@user.last_login)}
              </p>
            <% end %>
          </div>
          
          <div>
            <p class="text-sm text-gray-500 dark:text-gray-400 mb-1">Account Created</p>
            
            <p class="text-lg font-medium dark:text-gray-200">{format_datetime(@user.inserted_at)}</p>
            
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              {format_time_ago(@user.inserted_at)}
            </p>
          </div>
          
          <div>
            <p class="text-sm text-gray-500 dark:text-gray-400 mb-1">Last Updated</p>
            
            <p class="text-lg font-medium dark:text-gray-200">{format_datetime(@user.updated_at)}</p>
            
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              {format_time_ago(@user.updated_at)}
            </p>
          </div>
        </div>
      </div>
       <%!-- User Details --%>
      <div class="bg-white dark:bg-gray-800 p-6 rounded-lg shadow border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold mb-4 dark:text-gray-200">Personal Information</h3>
        
        <dl class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Email</dt>
            
            <dd class="mt-1 text-sm text-gray-900 dark:text-gray-100">{@user.email}</dd>
          </div>
          
          <div>
            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Full Name</dt>
            
            <dd class="mt-1 text-sm text-gray-900 dark:text-gray-100">{@user.profile.fullname}</dd>
          </div>
          
          <div>
            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Username</dt>
            
            <dd class="mt-1 text-sm text-gray-900 dark:text-gray-100">@{@user.username}</dd>
          </div>
          
          <div>
            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Phone Number</dt>
            
            <dd class="mt-1 text-sm text-gray-900 dark:text-gray-100">
              {(@user.profile && @user.profile.phone_number) || "-"}
            </dd>
          </div>
          
          <div>
            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Date of Birth</dt>
            
            <dd class="mt-1 text-sm text-gray-900 dark:text-gray-100">
              {(@user.profile && @user.profile.birthday) || "-"}
            </dd>
          </div>
          
          <div>
            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Gender</dt>
            
            <dd class="mt-1 text-sm text-gray-900 dark:text-gray-100">
              {(@user.profile && @user.profile.gender) || "-"}
            </dd>
          </div>
          
          <div>
            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Job Title</dt>
            
            <dd class="mt-1 text-sm text-gray-900 dark:text-gray-100">
              {(@user.profile && @user.profile.job_title) || "-"}
            </dd>
          </div>
          
          <div>
            <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">Account Type</dt>
            
            <dd class="mt-1 text-sm text-gray-900 dark:text-gray-100">{@user.user_type}</dd>
          </div>
        </dl>
      </div>
       <%!-- Actions --%>
      <div class="flex gap-4">
        <.link
          navigate={~p"/dashboard/user_manager/#{@user.username}/edit"}
          class="btn btn-primary"
        >
          <.icon name="hero-pencil-square" class="w-4 h-4 mr-2" /> Edit Profile
        </.link>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    user = Accounts.get_user_profile_by_username(params["username"])

    socket =
      socket
      |> assign(:page_title, "User Profile")
      |> assign(:user, user)

    {:ok, socket}
  end

  # Helper functions

  defp get_role_name(user) do
    if user.role do
      user.role.name
    else
      String.capitalize(user.user_role || "User")
    end
  end

  defp get_role_badge_class(user) do
    role_slug = if user.role, do: user.role.slug, else: user.user_role

    case role_slug do
      "super_admin" -> "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
      "manager" -> "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
      "curator" -> "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200"
    end
  end

  defp is_user_active?(user) do
    if user.last_login do
      days_since_login = DateTime.diff(DateTime.utc_now(), user.last_login, :day)
      days_since_login <= 30
    else
      false
    end
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
  end

  defp format_last_login(datetime) do
    days_ago = DateTime.diff(DateTime.utc_now(), datetime, :day)

    cond do
      days_ago == 0 -> "Today"
      days_ago == 1 -> "Yesterday"
      days_ago < 7 -> "#{days_ago} days ago"
      days_ago < 30 -> "#{div(days_ago, 7)} weeks ago"
      true -> "#{div(days_ago, 30)} months ago"
    end
  end

  defp format_time_ago(datetime) do
    days_ago = DateTime.diff(DateTime.utc_now(), datetime, :day)

    cond do
      days_ago == 0 -> "Today"
      days_ago == 1 -> "Yesterday"
      days_ago < 30 -> "#{days_ago} days ago"
      days_ago < 365 -> "#{div(days_ago, 30)} months ago"
      true -> "#{div(days_ago, 365)} years ago"
    end
  end
end
