defmodule CuratorianWeb.BlogController do
  use CuratorianWeb, :controller

  alias Curatorian.Blogs
  alias Curatorian.Blogs.Blog

  def index(conn, _params) do
    blogs = Blogs.list_blogs()
    render(conn, :index, blogs: blogs)
  end

  def new(conn, _params) do
    changeset = Blogs.change_blog(%Blog{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"blog" => blog_params}) do
    case Blogs.create_blog(blog_params) do
      {:ok, blog} ->
        conn
        |> put_flash(:info, "Blog created successfully.")
        |> redirect(to: ~p"/blogs/#{blog}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    blog = Blogs.get_blog!(id)
    render(conn, :show, blog: blog)
  end

  def edit(conn, %{"id" => id}) do
    blog = Blogs.get_blog!(id)
    changeset = Blogs.change_blog(blog)
    render(conn, :edit, blog: blog, changeset: changeset)
  end

  def update(conn, %{"id" => id, "blog" => blog_params}) do
    blog = Blogs.get_blog!(id)

    case Blogs.update_blog(blog, blog_params) do
      {:ok, blog} ->
        conn
        |> put_flash(:info, "Blog updated successfully.")
        |> redirect(to: ~p"/blogs/#{blog}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, blog: blog, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    blog = Blogs.get_blog!(id)
    {:ok, _blog} = Blogs.delete_blog(blog)

    conn
    |> put_flash(:info, "Blog deleted successfully.")
    |> redirect(to: ~p"/blogs")
  end
end
