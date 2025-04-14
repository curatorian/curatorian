defmodule CuratorianWeb.DashboardLive.UserManagerLive.Edit do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <.header>
      Edit User Profile
    </.header>

    <.back navigate="/dashboard/user_manager">Kembali</.back>

    <section>
      {@user.email}
    </section>
    """
  end

  def mount(params, _session, socket) do
    user = Accounts.get_user_profile_by_username(params["username"])
    # profile_changeset = Accounts.change_user_profile(user)
    dbg(user)

    socket =
      socket
      |> assign(:user, user)
      # |> assign(:profile_changeset, profile_changeset)
      |> assign(:page_title, "Edit user profile for #{user.profile.fullname}")

    {:ok, socket}
  end
end
