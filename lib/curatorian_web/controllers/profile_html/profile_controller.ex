defmodule CuratorianWeb.ProfileController do
  use CuratorianWeb, :controller

  alias Curatorian.Accounts
  alias Curatorian.Blogs

  def index(conn, %{"username" => username}) do
    user = Accounts.get_user_profile_by_username(username)
    active_tab = "blogs"

    conn =
      conn
      |> assign(:active_tab, active_tab)

    case user do
      nil ->
        conn
        |> assign(:info, "User not found")
        |> put_status(:not_found)
        |> put_view(CuratorianWeb.ErrorHTML)
        |> render(:"404")

      %Accounts.User{} ->
        blogs = Blogs.list_blogs_by_user(user.id)

        conn =
          conn
          |> assign(:user, user)
          |> assign(:blogs, blogs)

        render(conn, :index)
    end
  end

  def show_blog(conn, %{"username" => username, "slug" => slug}) do
    user = Accounts.get_user_profile_by_username(username)
    blog = Blogs.get_blog_by_slug(slug)

    with %Accounts.User{} <- user,
         %Blogs.Blog{} <- blog do
      conn =
        conn
        |> assign(:user, user)
        |> assign(:blog, blog)

      render(conn, :show_blog)
    else
      _ ->
        conn
        |> assign(:info, "Content not found")
        |> put_status(:not_found)
        |> put_view(CuratorianWeb.ErrorHTML)
        |> render(:"404")
    end
  end

  def show_posts(conn, %{"username" => username}) do
    user = Accounts.get_user_profile_by_username(username)

    with %Accounts.User{} <- user do
      conn =
        conn
        |> assign(:user, user)

      render(conn, :show_posts)
    else
      _ ->
        conn
        |> assign(:info, "User not found")
        |> put_status(:not_found)
        |> put_view(CuratorianWeb.ErrorHTML)
        |> render(:"404")
    end
  end
end
