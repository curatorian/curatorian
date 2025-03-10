defmodule Curatorian.Blogs do
  @moduledoc """
  The Blogs context.
  """

  import Ecto.Query, warn: false
  alias Curatorian.Repo

  alias Curatorian.Blogs.Blog

  @doc """
  Returns the list of blogs.

  ## Examples

      iex> list_blogs()
      [%Blog{}, ...]

  """
  def list_blogs do
    Repo.all(Blog)
  end

  def list_blogs_by_user(user_id) do
    Repo.all(
      from(b in Blog,
        where: b.user_id == ^user_id,
        preload: [user: :profile]
      )
    )
  end

  @doc """
  Gets a single blog.

  Raises `Ecto.NoResultsError` if the Blog does not exist.

  ## Examples

      iex> get_blog!(123)
      %Blog{}

      iex> get_blog!(456)
      ** (Ecto.NoResultsError)

  """
  def get_blog!(id), do: Repo.get!(Blog, id)

  def get_blog_by_slug(slug) do
    Blog
    |> Repo.get_by(slug: slug)
    |> Repo.preload(:user)
  end

  @doc """
  Creates a blog.

  ## Examples

      iex> create_blog(%{field: value})
      {:ok, %Blog{}}

      iex> create_blog(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_blog(attrs \\ %{}) do
    %Blog{}
    |> Blog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a blog.

  ## Examples

      iex> update_blog(blog, %{field: new_value})
      {:ok, %Blog{}}

      iex> update_blog(blog, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_blog(%Blog{} = blog, attrs) do
    blog
    |> Blog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a blog.

  ## Examples

      iex> delete_blog(blog)
      {:ok, %Blog{}}

      iex> delete_blog(blog)
      {:error, %Ecto.Changeset{}}

  """
  def delete_blog(%Blog{} = blog) do
    Repo.delete(blog)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking blog changes.

  ## Examples

      iex> change_blog(blog)
      %Ecto.Changeset{data: %Blog{}}

  """
  def change_blog(%Blog{} = blog, attrs \\ %{}) do
    Blog.changeset(blog, attrs)
  end

  @doc """
  Count total blogs user has.
  ## Examples

      iex> count_blogs_by_user(user_id)
      5
  """
  def count_blogs_by_user(user_id) do
    Repo.aggregate(Blog, :count, :id, where: [user_id: user_id])
  end
end
