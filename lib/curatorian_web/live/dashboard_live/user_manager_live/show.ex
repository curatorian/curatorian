defmodule CuratorianWeb.DashboardLive.UserManagerLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <.header>
      User Profile
    </.header>

    <.back navigate="/dashboard/user_manager">Kembali</.back>

    <div class="user-profile">
      <div class="profile-header">
        <h2>{@user.profile.fullname}</h2>
        
        <p>@{@user.username}</p>
      </div>
      
      <div class="profile-details">
        <h3>Details</h3>
        
        <ul>
          <li><strong>Email:</strong> {@user.email}</li>
          
          <li>
            <strong>Joined:</strong> {@user.inserted_at}
          </li>
        </ul>
      </div>
      
      <div class="profile-actions">
        <.link patch={~p"/dashboard/user_manager/#{@user.username}/edit"} class="btn btn-primary">
          Edit Profile
        </.link>
         <button class="btn btn-cancel">Delete User</button>
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
end
