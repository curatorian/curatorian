defmodule CuratorianWeb.ProfileController do
  use CuratorianWeb, :controller

  alias Curatorian.Accounts
  alias Curatorian.Blogs

  def index(conn, %{"username" => username}) do
    user = Accounts.get_user_profile_by_username(username)
    blogs = Blogs.list_blogs_by_user(user.id)

    conn =
      conn
      |> assign(:user, user)
      |> assign(:blogs, blogs)

    render(conn, :index)
  end

  def show(conn, %{"username" => username, "slug" => slug}) do
    user = Accounts.get_user_profile_by_username(username)
    blog = Blogs.get_blog_by_slug(slug)

    conn =
      conn
      |> assign(:user, user)
      |> assign(:blog, blog)

    render(conn, :show)
  end
end
