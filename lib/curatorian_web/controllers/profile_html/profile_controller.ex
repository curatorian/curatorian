defmodule CuratorianWeb.ProfileController do
  use CuratorianWeb, :controller

  alias Curatorian.Accounts

  def index(conn, %{"username" => username}) do
    user = Accounts.get_user_profile_by_username(username)

    dbg(user)

    render(conn, :index, user: user)
  end
end
