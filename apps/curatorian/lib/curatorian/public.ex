defmodule Curatorian.Public do
  @moduledoc """
  Context for querying publicly visible data from shared atrium/voile tables.

  All queries are read-only and enforce visibility rules:
  - UserProfile: is_public = true, deleted_at IS NULL
  - OrgPage: is_public = true, deleted_at IS NULL
  - Collection: status = 'published', access_level = 'public'
  """

  import Ecto.Query

  alias Curatorian.Repo
  alias Curatorian.Public.{UserProfile, OrgPage, Collection, NodeProfile, Unit, BlogPost, BlogPostComment}

  @page_size 12

  # ---------------------------------------------------------------------------
  # User Profiles
  # ---------------------------------------------------------------------------

  def list_profiles(search \\ "", opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    offset = (page - 1) * @page_size
    institution_type = Keyword.get(opts, :institution_type, nil)

    from(p in UserProfile,
      where: p.is_public == true and is_nil(p.deleted_at)
    )
    |> filter_by_institution_type(institution_type)
    |> search_profiles(search)
    |> order_by([p], desc: p.follower_count, asc: p.display_name)
    |> limit(@page_size)
    |> offset(^offset)
    |> Repo.all()
  end

  def count_profiles(search \\ "", opts \\ []) do
    institution_type = Keyword.get(opts, :institution_type, nil)

    from(p in UserProfile,
      where: p.is_public == true and is_nil(p.deleted_at)
    )
    |> filter_by_institution_type(institution_type)
    |> search_profiles(search)
    |> Repo.aggregate(:count, :id)
  end

  def get_public_profile(username) do
    Repo.get_by(UserProfile, username: username, is_public: true)
  end

  defp search_profiles(query, ""), do: query

  defp search_profiles(query, search) do
    term = "%#{search}%"

    where(
      query,
      [p],
      ilike(p.display_name, ^term) or
        ilike(p.username, ^term) or
        ilike(p.headline, ^term) or
        ilike(p.city, ^term)
    )
  end

  defp filter_by_institution_type(query, nil), do: query

  defp filter_by_institution_type(query, type) do
    where(query, [p], p.institution_type == ^type)
  end

  # ---------------------------------------------------------------------------
  # Org Pages
  # ---------------------------------------------------------------------------

  def list_org_pages(search \\ "", opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    offset = (page - 1) * @page_size
    category = Keyword.get(opts, :category, nil)

    from(o in OrgPage,
      where: o.is_public == true and is_nil(o.deleted_at)
    )
    |> filter_by_category(category)
    |> search_org_pages(search)
    |> order_by([o], desc: o.follower_count, asc: o.name)
    |> limit(@page_size)
    |> offset(^offset)
    |> Repo.all()
  end

  def count_org_pages(search \\ "", opts \\ []) do
    category = Keyword.get(opts, :category, nil)

    from(o in OrgPage,
      where: o.is_public == true and is_nil(o.deleted_at)
    )
    |> filter_by_category(category)
    |> search_org_pages(search)
    |> Repo.aggregate(:count, :id)
  end

  def get_public_org_page(slug) do
    Repo.get_by(OrgPage, slug: slug, is_public: true)
  end

  defp search_org_pages(query, ""), do: query

  defp search_org_pages(query, search) do
    term = "%#{search}%"

    where(
      query,
      [o],
      ilike(o.name, ^term) or
        ilike(o.tagline, ^term) or
        ilike(o.city, ^term) or
        ilike(o.description, ^term)
    )
  end

  defp filter_by_category(query, nil), do: query

  defp filter_by_category(query, category) do
    where(query, [o], o.category == ^category)
  end

  # ---------------------------------------------------------------------------
  # Collections
  # ---------------------------------------------------------------------------

  def list_collections(search \\ "", opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    offset = (page - 1) * @page_size
    collection_type = Keyword.get(opts, :collection_type, nil)

    from(c in Collection,
      where: c.status == "published" and c.access_level == "public",
      preload: [:unit]
    )
    |> filter_by_collection_type(collection_type)
    |> search_collections(search)
    |> order_by([c], desc: c.inserted_at)
    |> limit(@page_size)
    |> offset(^offset)
    |> Repo.all()
  end

  def count_collections(search \\ "", opts \\ []) do
    collection_type = Keyword.get(opts, :collection_type, nil)

    from(c in Collection,
      where: c.status == "published" and c.access_level == "public"
    )
    |> filter_by_collection_type(collection_type)
    |> search_collections(search)
    |> Repo.aggregate(:count, :id)
  end

  def get_public_collection(id) do
    from(c in Collection,
      where: c.id == ^id and c.status == "published" and c.access_level == "public",
      preload: [:unit]
    )
    |> Repo.one()
  end

  defp search_collections(query, ""), do: query

  defp search_collections(query, search) do
    term = "%#{search}%"
    where(query, [c], ilike(c.title, ^term) or ilike(c.description, ^term))
  end

  defp filter_by_collection_type(query, nil), do: query

  defp filter_by_collection_type(query, type) do
    where(query, [c], c.collection_type == ^type)
  end

  # ---------------------------------------------------------------------------
  # Node Profiles (Organizations via atrium.node_profiles + voile.nodes)
  # ---------------------------------------------------------------------------

  def list_node_profiles(search \\ "", opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    offset = (page - 1) * @page_size
    institution_type = Keyword.get(opts, :institution_type, nil)

    base_query =
      from(np in NodeProfile,
        join: n in Unit,
        on: np.voile_node_id == n.id,
        where: np.status == :approved and is_nil(np.deleted_at),
        select: %{profile: np, node: n}
      )

    base_query
    |> filter_node_by_institution_type(institution_type)
    |> search_node_profiles(search)
    |> order_by([np, n], asc: np.institution_name)
    |> limit(@page_size)
    |> offset(^offset)
    |> Repo.all()
  end

  def count_node_profiles(search \\ "", opts \\ []) do
    institution_type = Keyword.get(opts, :institution_type, nil)

    from(np in NodeProfile,
      join: n in Unit,
      on: np.voile_node_id == n.id,
      where: np.status == :approved and is_nil(np.deleted_at),
      select: np
    )
    |> filter_node_by_institution_type(institution_type)
    |> search_node_profiles(search)
    |> Repo.aggregate(:count, :id)
  end

  def get_node_profile(id) do
    result =
      from(np in NodeProfile,
        join: n in Unit,
        on: np.voile_node_id == n.id,
        where: np.id == ^id and np.status == :approved,
        select: %{profile: np, node: n}
      )
      |> Repo.one()

    result
  end

  defp search_node_profiles(query, ""), do: query

  defp search_node_profiles(query, search) do
    term = "%#{search}%"

    where(
      query,
      [np, n],
      ilike(np.institution_name, ^term) or
        ilike(n.name, ^term) or
        ilike(np.city, ^term)
    )
  end

  defp filter_node_by_institution_type(query, nil), do: query

  defp filter_node_by_institution_type(query, type) do
    where(query, [np, _n], np.institution_type == ^type)
  end

  # ---------------------------------------------------------------------------
  # Blog Posts (public read + comment creation)
  # ---------------------------------------------------------------------------

  @doc "Returns published blog posts for a user, newest first."
  def list_user_blog_posts(voile_user_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    limit = Keyword.get(opts, :limit, 5)

    from(p in BlogPost,
      where:
        p.voile_user_id == ^voile_user_id and
          p.status == "published" and
          is_nil(p.deleted_at),
      order_by: [desc: p.published_at],
      limit: ^limit,
      offset: ^((page - 1) * limit)
    )
    |> Repo.all()
  end

  @doc "Fetches a single published blog post by username and slug."
  def get_public_blog_post(username, slug) do
    from(p in BlogPost,
      join: u in UserProfile,
      on: u.voile_user_id == p.voile_user_id,
      where:
        u.username == ^username and
          p.slug == ^slug and
          p.status == "published" and
          is_nil(p.deleted_at)
    )
    |> Repo.one()
  end

  @doc "Returns visible (non-hidden, non-deleted) comments for a post, oldest first."
  def list_public_comments(blog_post_id) do
    from(c in BlogPostComment,
      where:
        c.blog_post_id == ^blog_post_id and
          c.is_hidden == false and
          is_nil(c.deleted_at),
      order_by: [asc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Creates a comment on a blog post from a logged-in Curatorian user.
  Denormalizes author info and increments the post's comment_count.
  """
  def create_blog_comment(blog_post_id, user, body) do
    attrs = %{
      "blog_post_id" => blog_post_id,
      "voile_user_id" => to_string(user.id),
      "author_username" => user.username || "",
      "author_display_name" => user.fullname || user.username || "",
      "author_avatar_url" => user.user_image,
      "body" => body
    }

    result =
      %BlogPostComment{}
      |> BlogPostComment.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, _} ->
        from(p in BlogPost, where: p.id == ^blog_post_id)
        |> Repo.update_all(inc: [comment_count: 1])

        result

      _ ->
        result
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def page_size, do: @page_size

  @doc """
  Prefix a stored asset path with the Atrium base URL when the path is relative
  (i.e. starts with "/"). Fully-qualified URLs are returned unchanged.
  Returns nil when the input is nil or empty.
  """
  def asset_url(nil), do: nil
  def asset_url(""), do: nil

  def asset_url(path) when is_binary(path) do
    if String.starts_with?(path, "http") do
      path
    else
      atrium_url = Application.get_env(:curatorian, :atrium_url, "http://localhost:4001")
      atrium_url <> path
    end
  end
end
