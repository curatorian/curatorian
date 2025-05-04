defmodule Curatorian.Blogs do
  @moduledoc """
  The Blogs context.
  """

  import Ecto.Query, warn: false
  alias Curatorian.Repo

  alias Curatorian.Blogs.{Blog, Category, Tag}

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
    |> Repo.preload([:tags, :categories])
    |> Repo.preload(user: [:profile])
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
    |> Ecto.Changeset.put_assoc(:tags, attrs["tags"])
    |> Ecto.Changeset.put_assoc(:categories, attrs["categories"])
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
    blog =
      blog
      |> Repo.preload([:tags, :categories])

    blog
    |> Blog.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:tags, attrs["tags"])
    |> Ecto.Changeset.put_assoc(:categories, attrs["categories"])
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
    from(b in Blog,
      where: b.user_id == ^user_id
    )
    |> Repo.aggregate(:count, :id)
  end

  # Tags
  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end

  def list_tags, do: Repo.all(Tag)
  def get_tag!(id), do: Repo.get!(Tag, id)
  def get_tag_by_slug(slug), do: Repo.get_by(Tag, slug: slug)

  def get_or_create_tag(tag) do
    case get_tag_by_slug(tag.slug) do
      nil ->
        %Tag{}
        |> Tag.changeset(%{name: tag.name, slug: tag.slug})
        |> Repo.insert()
        |> case do
          {:ok, tag} -> {:ok, tag}
          {:error, changeset} -> {:error, changeset}
        end

      tag ->
        {:ok, tag}
    end
  end

  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  def list_blogs_by_tag(tag_id) do
    Repo.all(
      from(b in Blog,
        join: t in assoc(b, :tags),
        where: t.id == ^tag_id,
        preload: [user: :profile]
      )
    )
  end

  # Categories
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  def list_categories, do: Repo.all(Category)
  def get_category!(id), do: Repo.get!(Category, id)
  def get_category_by_slug(slug), do: Repo.get_by(Category, slug: slug)

  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  def list_blogs_by_category(category_id) do
    Repo.all(
      from(b in Blog,
        join: c in assoc(b, :categories),
        where: c.id == ^category_id,
        preload: [user: :profile]
      )
    )
  end
end
