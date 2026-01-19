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
        if user.is_verified do
          blogs = Blogs.list_blogs_by_user(user.id)

          conn =
            conn
            |> assign(:user, user)
            |> assign(:blogs, blogs)

          render(conn, :index)
        else
          conn
          |> assign(:info, "User not found")
          |> put_status(:not_found)
          |> put_view(CuratorianWeb.ErrorHTML)
          |> render(:"404")
        end
    end
  end

  def blogs(conn, %{"username" => username}) do
    user = Accounts.get_user_profile_by_username(username)

    active_tab = "blogs"

    conn =
      conn
      |> assign(:active_tab, active_tab)

    with %Accounts.User{} <- user do
      if user.is_verified do
        blogs = Blogs.list_blogs_by_user(user.id)

        conn =
          conn
          |> assign(:user, user)
          |> assign(:blogs, blogs)

        render(conn, :profile_blog)
      else
        conn
        |> assign(:info, "User not found")
        |> put_status(:not_found)
        |> put_view(CuratorianWeb.ErrorHTML)
        |> render(:"404")
      end
    else
      _ ->
        conn
        |> assign(:info, "User not found")
        |> put_status(:not_found)
        |> put_view(CuratorianWeb.ErrorHTML)
        |> render(:"404")
    end
  end

  def show_blog(conn, %{"username" => username, "slug" => slug}) do
    user = Accounts.get_user_profile_by_username(username)
    blog = Blogs.get_blog_by_slug(slug)

    with %Accounts.User{} <- user,
         %Blogs.Blog{} <- blog do
      if user.is_verified do
        conn =
          conn
          |> assign(:user, user)
          |> assign(:blog, blog)

        render(conn, :show_blog)
      else
        conn
        |> assign(:info, "Content not found")
        |> put_status(:not_found)
        |> put_view(CuratorianWeb.ErrorHTML)
        |> render(:"404")
      end
    else
      _ ->
        conn
        |> assign(:info, "Content not found")
        |> put_status(:not_found)
        |> put_view(CuratorianWeb.ErrorHTML)
        |> render(:"404")
    end
  end

  def posts(conn, %{"username" => username}) do
    user = Accounts.get_user_profile_by_username(username)

    active_tab = "posts"

    conn =
      conn
      |> assign(:active_tab, active_tab)

    with %Accounts.User{} <- user do
      if user.is_verified do
        posts = []

        conn =
          conn
          |> assign(:user, user)
          |> assign(:posts, posts)

        render(conn, :profile_post)
      else
        conn
        |> assign(:info, "User not found")
        |> put_status(:not_found)
        |> put_view(CuratorianWeb.ErrorHTML)
        |> render(:"404")
      end
    else
      _ ->
        conn
        |> assign(:info, "User not found")
        |> put_status(:not_found)
        |> put_view(CuratorianWeb.ErrorHTML)
        |> render(:"404")
    end
  end

  def show_posts(conn, %{"username" => username}, %{"id" => _id}) do
    user = Accounts.get_user_profile_by_username(username)

    with %Accounts.User{} <- user do
      if user.is_verified do
        conn =
          conn
          |> assign(:user, user)

        render(conn, :show_posts)
      else
        conn
        |> assign(:info, "User not found")
        |> put_status(:not_found)
        |> put_view(CuratorianWeb.ErrorHTML)
        |> render(:"404")
      end
    else
      _ ->
        conn
        |> assign(:info, "User not found")
        |> put_status(:not_found)
        |> put_view(CuratorianWeb.ErrorHTML)
        |> render(:"404")
    end
  end

  def works(conn, %{"username" => username}) do
    user = Accounts.get_user_profile_by_username(username)

    active_tab = "works"

    conn =
      conn
      |> assign(:active_tab, active_tab)

    with %Accounts.User{} <- user do
      if user.is_verified do
        works = []

        conn =
          conn
          |> assign(:user, user)
          |> assign(:works, works)

        render(conn, :profile_work)
      else
        conn
        |> assign(:info, "User not found")
        |> put_status(:not_found)
        |> put_view(CuratorianWeb.ErrorHTML)
        |> render(:"404")
      end
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
