defmodule CuratorianWeb.ProfileController do
  use CuratorianWeb, :controller

  alias Curatorian.Accounts

  def index(conn, _params) do
    render(conn, :index)
  end

  def show(conn, %{"username" => username}) do
    user = Accounts.get_user_profile_by_username(username)

    dbg(user)

    render(conn, :show, user: user)
  end
end
