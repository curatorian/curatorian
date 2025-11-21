defmodule CuratorianWeb.DashboardLive.UserManagerLive.Show do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <.header>User Profile</.header>
     <.button navigate="/dashboard/user_manager">Kembali</.button>
    <div class="user-profile">
      <div class="profile-header">
        <h2>{@user.profile.fullname}</h2>
        
        <%= if @user.profile.user_image do %>
          <img
            src={@user.profile.user_image}
            class="w-32 h-32 rounded-xl"
            referrerPolicy="no-referrer"
          />
        <% else %>
          <img
            src={~p"/images/default.png"}
            class="w-32 h-32 rounded-xl"
            referrerPolicy="no-referrer"
          />
        <% end %>
        
        <p>@{@user.username}</p>
      </div>
      
      <div class="bg-violet-50 p-4 rounded-lg shadow-md mt-5">
        <h5>Details</h5>
        
        <div class="grid grid-cols-3 gap-2 w-full max-w-md">
          <div class="flex flex-col gap-4">
            <p>Email</p>
            
            <p>Nama Lengkap</p>
            
            <p>Username</p>
            
            <p>Nomor Telepon</p>
            
            <p>Tanggal Lahir</p>
            
            <p>Jenis Kelamin</p>
            
            <p>Pekerjaan</p>
            
            <p>Tipe User</p>
            
            <p>User Role</p>
          </div>
          
          <div class="col-span-2 flex flex-col gap-4">
            <p>: {@user.email}</p>
            
            <p>: {@user.profile.fullname}</p>
            
            <p>: {@user.username}</p>
            
            <p>: {@user.profile.phone_number}</p>
            
            <p>: {@user.profile.birthday}</p>
            
            <p>: {@user.profile.gender}</p>
            
            <p>: {(@user.profile && @user.profile.job_title) || "-"}</p>
            
            <p>: {@user.user_type}</p>
            
            <p>: {@user.user_role}</p>
          </div>
        </div>
      </div>
      
      <div class="flex gap-4 my-5">
        <.link
          patch={~p"/dashboard/user_manager/#{@user.username}/edit"}
          class="btn btn-primary no-underline"
        >
          Edit Profile
        </.link> <button class="btn btn-cancel">Delete User</button>
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
