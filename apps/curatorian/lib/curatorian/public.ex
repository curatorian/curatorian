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

  alias Curatorian.Public.{
    UserProfile,
    UserFollow,
    DirectMessageThread,
    OrgPage,
    Collection,
    NodeProfile,
    Unit,
    BlogPost,
    BlogPostComment,
    UserRole,
    Role,
    JobPosting,
    JobApplication,
    Event,
    EventAttendance,
    EventRegistration,
    OrgPageFollower,
    CrowdfundingCampaign,
    ExchangeOffer,
    ExchangeWishlist
  }

  @page_size 12

  def page_size, do: @page_size

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

  # ---------------------------------------------------------------------------
  # Library Classifications (DDC / UDC)

  def list_classifications(search \\ "", opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, @page_size)
    system = Keyword.get(opts, :system, nil)
    offset = (page - 1) * per_page

    from(c in "classifications",
      where: c.status == "published"
    )
    |> filter_classification_system(system)
    |> search_classifications(search)
    |> order_by([c], asc: c.system, asc: c.code)
    |> limit(^per_page)
    |> offset(^offset)
    |> select([c], map(c, [:id, :system, :code, :subject, :status]))
    |> Repo.all()
  end

  def list_classifications_for_tree(search \\ "", system \\ nil) do
    from(c in "classifications",
      where: c.status == "published"
    )
    |> filter_classification_system(system)
    |> search_classifications(search)
    |> order_by([c], asc: c.system, asc: c.code)
    |> select([c], map(c, [:id, :system, :code, :subject, :status]))
    |> Repo.all()
  end

  def count_classifications(search \\ "", opts \\ []) do
    system = Keyword.get(opts, :system, nil)

    from(c in "classifications",
      where: c.status == "published"
    )
    |> filter_classification_system(system)
    |> search_classifications(search)
    |> Repo.aggregate(:count, :id)
  end

  defp filter_classification_system(query, nil), do: query

  defp filter_classification_system(query, system) when system in ["DDC", "UDC"] do
    where(query, [c], c.system == ^system)
  end

  defp filter_classification_system(query, _), do: query

  defp search_classifications(query, ""), do: query

  defp search_classifications(query, search) do
    term = "%#{search}%"

    where(
      query,
      [c],
      ilike(c.code, ^term) or
        ilike(c.subject, ^term) or
        ilike(c.system, ^term)
    )
  end

  def get_public_profile(username) do
    UserProfile
    |> where([u], u.username == ^username)
    |> where([u], is_nil(u.deleted_at))
    |> Repo.one()
  end

  def follow_user(follower_id, following_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:follow, fn _ ->
      %UserFollow{}
      |> UserFollow.changeset(%{follower_id: follower_id, following_id: following_id})
    end)
    |> Ecto.Multi.update_all(
      :inc_follower_count,
      from(p in UserProfile,
        where: p.voile_user_id == ^following_id,
        update: [inc: [follower_count: 1]]
      ),
      []
    )
    |> Ecto.Multi.update_all(
      :inc_following_count,
      from(p in UserProfile,
        where: p.voile_user_id == ^follower_id,
        update: [inc: [following_count: 1]]
      ),
      []
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{follow: follow}} -> {:ok, follow}
      {:error, :follow, changeset, _} -> {:error, changeset}
      {:error, _step, reason, _} -> {:error, reason}
    end
  end

  def unfollow_user(follower_id, following_id) do
    case Repo.get_by(UserFollow, follower_id: follower_id, following_id: following_id) do
      nil ->
        {:error, :not_found}

      follow ->
        Ecto.Multi.new()
        |> Ecto.Multi.delete(:unfollow, follow)
        |> Ecto.Multi.update_all(
          :dec_follower_count,
          from(p in UserProfile,
            where: p.voile_user_id == ^following_id,
            update: [inc: [follower_count: -1]]
          ),
          []
        )
        |> Ecto.Multi.update_all(
          :dec_following_count,
          from(p in UserProfile,
            where: p.voile_user_id == ^follower_id,
            update: [inc: [following_count: -1]]
          ),
          []
        )
        |> Repo.transaction()
        |> case do
          {:ok, _} -> :ok
          {:error, _step, reason, _} -> {:error, reason}
        end
    end
  end

  def following?(follower_id, following_id) do
    Repo.exists?(
      from(f in UserFollow,
        where: f.follower_id == ^follower_id and f.following_id == ^following_id
      )
    )
  end

  def get_or_create_thread(user_a_id, user_b_id) do
    {participant_a, participant_b} =
      if user_a_id < user_b_id, do: {user_a_id, user_b_id}, else: {user_b_id, user_a_id}

    case Repo.get_by(DirectMessageThread,
           participant_a_id: participant_a,
           participant_b_id: participant_b
         ) do
      nil ->
        %DirectMessageThread{}
        |> DirectMessageThread.changeset(%{
          participant_a_id: participant_a,
          participant_b_id: participant_b
        })
        |> Repo.insert()

      thread ->
        {:ok, thread}
    end
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

  def list_collections_for_node(voile_node_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    offset = (page - 1) * @page_size

    from(c in Collection,
      where:
        c.unit_id == ^voile_node_id and
          c.status == "published" and
          c.access_level == "public",
      order_by: [desc: c.inserted_at],
      limit: @page_size,
      offset: ^offset
    )
    |> Repo.all()
  end

  def count_collections_for_node(voile_node_id) do
    from(c in Collection,
      where:
        c.unit_id == ^voile_node_id and
          c.status == "published" and
          c.access_level == "public"
    )
    |> Repo.aggregate(:count, :id)
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
  # Staff / Members (atrium.user_roles → atrium.user_profiles)
  # ---------------------------------------------------------------------------

  @role_order %{"super_admin" => -1, "admin" => 0, "staff" => 1, "viewer" => 2}

  def list_staff_for_node(voile_node_id) do
    now = DateTime.utc_now()

    role_members_query =
      from ur in UserRole,
        join: up in UserProfile,
        on: up.voile_user_id == ur.voile_user_id,
        join: r in Role,
        on: r.id == ur.role_id,
        where:
          (ur.voile_node_id == ^voile_node_id or
             (is_nil(ur.voile_node_id) and r.scope == "platform" and ^voile_node_id == 1)) and
            ur.status == :active and
            (is_nil(ur.expires_at) or ur.expires_at > ^now) and
            up.is_public == true and
            is_nil(up.deleted_at),
        select: %{
          id: up.id,
          user_id: up.voile_user_id,
          username: up.username,
          display_name: up.display_name,
          avatar_url: up.avatar_url,
          headline: up.headline,
          city: up.city,
          province: up.province,
          is_verified: up.is_verified,
          role_name: r.name
        }

    role_members = Repo.all(role_members_query)
    user_ids = MapSet.new(Enum.map(role_members, & &1.user_id))

    fallback_query =
      from up in UserProfile,
        where:
          up.voile_node_id == ^voile_node_id and
            up.is_public == true and
            is_nil(up.deleted_at) and
            up.voile_user_id not in ^MapSet.to_list(user_ids),
        select: %{
          id: up.id,
          user_id: up.voile_user_id,
          username: up.username,
          display_name: up.display_name,
          avatar_url: up.avatar_url,
          headline: up.headline,
          city: up.city,
          province: up.province,
          is_verified: up.is_verified,
          role_name: "viewer"
        }

    fallback_members = Repo.all(fallback_query)

    (role_members ++ fallback_members)
    |> Enum.uniq_by(& &1.user_id)
    |> Enum.sort_by(fn m -> Map.get(@role_order, m.role_name, 99) end)
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
        left_join: o in OrgPage,
        on:
          np.voile_node_id == o.voile_node_id and
            o.is_public == true and
            is_nil(o.deleted_at),
        where: np.id == ^id and np.status == :approved,
        select: %{profile: np, node: n, org_page: o}
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
  # Job Postings

  def list_job_postings(opts \\ []) do
    search = Keyword.get(opts, :search, "")
    status = Keyword.get(opts, :status)
    employment_type = Keyword.get(opts, :employment_type)
    category = Keyword.get(opts, :category)
    location_type = Keyword.get(opts, :location_type)
    page = Keyword.get(opts, :page, 1)
    offset = (page - 1) * @page_size

    from(j in JobPosting,
      where: is_nil(j.deleted_at)
    )
    |> filter_job_status(status)
    |> filter_job_employment_type(employment_type)
    |> filter_job_category(category)
    |> filter_job_location_type(location_type)
    |> filter_job_search(search)
    |> order_by([j], desc: j.is_featured, desc: j.posted_at, desc: j.inserted_at)
    |> limit(@page_size)
    |> offset(^offset)
    |> Repo.all()
  end

  def list_active_job_postings(opts \\ []) do
    now = DateTime.utc_now()

    opts
    |> Keyword.put(:status, :active)
    |> list_job_postings()
    |> Enum.filter(fn posting ->
      posting.application_deadline == nil or
        DateTime.compare(posting.application_deadline, now) == :gt
    end)
  end

  def get_job_posting_by_slug(slug) do
    from(j in JobPosting,
      where:
        j.slug == ^slug and
          j.status == :active and
          is_nil(j.deleted_at)
    )
    |> Repo.one()
  end

  def get_job_posting!(slug) do
    case get_job_posting_by_slug(slug) do
      nil -> raise Ecto.NoResultsError, queryable: JobPosting
      posting -> posting
    end
  end

  def get_job_posting_by_id!(id) do
    Repo.get!(JobPosting, id)
  end

  def get_application_by_user_and_posting(user_id, posting_id) do
    Repo.get_by(JobApplication,
      voile_user_id: user_id,
      job_posting_id: posting_id
    )
  end

  def list_applications_by_user(user_id) do
    from(a in JobApplication,
      where: a.voile_user_id == ^user_id,
      order_by: [desc: a.applied_at]
    )
    |> Repo.all()
  end

  def create_application(attrs) do
    attrs = Map.put_new(attrs, "applied_at", DateTime.utc_now())

    %JobApplication{}
    |> JobApplication.changeset(attrs)
    |> Repo.insert()
  end

  defp filter_job_status(query, nil), do: query
  defp filter_job_status(query, status), do: where(query, [j], j.status == ^status)

  defp filter_job_employment_type(query, nil), do: query

  defp filter_job_employment_type(query, value),
    do: where(query, [j], j.employment_type == ^value)

  defp filter_job_category(query, nil), do: query
  defp filter_job_category(query, value), do: where(query, [j], j.category == ^value)

  defp filter_job_location_type(query, nil), do: query
  defp filter_job_location_type(query, value), do: where(query, [j], j.location_type == ^value)

  defp filter_job_search(query, ""), do: query
  defp filter_job_search(query, nil), do: query

  defp filter_job_search(query, search) when is_binary(search) do
    term = "%#{search}%"

    where(
      query,
      [j],
      ilike(j.title, ^term) or
        ilike(j.institution_name, ^term) or
        ilike(j.description, ^term) or
        ilike(j.location_city, ^term)
    )
  end

  # ---------------------------------------------------------------------------
  # Events
  # ---------------------------------------------------------------------------

  def list_events(search \\ "", opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    offset = (page - 1) * @page_size
    event_type = Keyword.get(opts, :event_type)
    category = Keyword.get(opts, :category)
    mode = Keyword.get(opts, :mode)
    starts_at_after = Keyword.get(opts, :starts_at_after)

    now = DateTime.utc_now()

    from(e in Event,
      where:
        is_nil(e.deleted_at) and
          e.status in [:published, :ongoing] and
          (e.starts_at >= ^now or e.status == :ongoing)
    )
    |> filter_event_type(event_type)
    |> filter_event_category(category)
    |> filter_event_mode(mode)
    |> filter_event_starts_after(starts_at_after)
    |> filter_event_search(search)
    |> order_by([e], desc: e.is_paid, desc: e.starts_at)
    |> limit(@page_size)
    |> offset(^offset)
    |> Repo.all()
  end

  def count_events(search \\ "", opts \\ []) do
    event_type = Keyword.get(opts, :event_type)
    category = Keyword.get(opts, :category)
    mode = Keyword.get(opts, :mode)
    starts_at_after = Keyword.get(opts, :starts_at_after)

    now = DateTime.utc_now()

    from(e in Event,
      where:
        is_nil(e.deleted_at) and
          e.status in [:published, :ongoing] and
          (e.starts_at >= ^now or e.status == :ongoing)
    )
    |> filter_event_type(event_type)
    |> filter_event_category(category)
    |> filter_event_mode(mode)
    |> filter_event_starts_after(starts_at_after)
    |> filter_event_search(search)
    |> Repo.aggregate(:count, :id)
  end

  def get_event_by_slug(slug) do
    now = DateTime.utc_now()

    from(e in Event,
      where:
        e.slug == ^slug and
          is_nil(e.deleted_at) and
          e.status in [:published, :ongoing] and
          (e.starts_at >= ^now or e.status == :ongoing)
    )
    |> Repo.one()
  end

  def get_event_by_slug!(slug) do
    case get_event_by_slug(slug) do
      nil -> raise Ecto.NoResultsError, queryable: Event
      event -> event
    end
  end

  def check_event_registration(user_id, event_id) do
    Repo.get_by(EventAttendance,
      voile_user_id: user_id,
      event_id: event_id
    )
  end

  defp filter_event_type(query, nil), do: query

  defp filter_event_type(query, event_type),
    do: where(query, [e], e.event_type == ^String.to_atom(event_type))

  defp filter_event_category(query, nil), do: query

  defp filter_event_category(query, category),
    do: where(query, [e], e.category == ^String.to_atom(category))

  defp filter_event_mode(query, nil), do: query
  defp filter_event_mode(query, mode), do: where(query, [e], e.mode == ^String.to_atom(mode))

  defp filter_event_starts_after(query, nil), do: query

  defp filter_event_starts_after(query, %Date{} = date) do
    where(query, [e], e.starts_at >= ^DateTime.new!(date, ~T[00:00:00], "Etc/UTC"))
  end

  defp filter_event_starts_after(query, date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> filter_event_starts_after(query, date)
      _ -> query
    end
  end

  defp filter_event_search(query, ""), do: query

  defp filter_event_search(query, search) when is_binary(search) do
    term = "%#{search}%"

    where(
      query,
      [e],
      ilike(e.title, ^term) or
        ilike(e.description, ^term) or
        ilike(e.venue_city, ^term) or
        ilike(e.venue_province, ^term)
    )
  end

  # ---------------------------------------------------------------------------

  @doc """
  Prefix a stored asset path with the Atrium base URL when the path is relative
  (i.e. starts with "/"). Fully-qualified URLs are returned unchanged.
  Returns nil when the input is nil or empty.
  """
  def asset_url(nil), do: nil
  def asset_url(""), do: nil

  def asset_url(path) when is_binary(path) do
    cond do
      path == "" ->
        nil

      String.starts_with?(path, "http") ->
        path

      Code.ensure_loaded?(Atrium.Storage) && function_exported?(Atrium.Storage, :url_for, 1) ->
        apply(Atrium.Storage, :url_for, [path])

      true ->
        atrium_url = Application.get_env(:curatorian, :atrium_url, "http://localhost:4001")
        atrium_url <> path
    end
  end

  # ---------------------------------------------------------------------------
  # Foyer helper queries
  # ---------------------------------------------------------------------------

  def list_event_registrations_by_user(voile_user_id) do
    from(r in EventRegistration,
      where: r.voile_user_id == ^voile_user_id,
      order_by: [desc: r.registered_at]
    )
    |> Repo.all()
  end

  def list_events_created_by_user(voile_user_id) do
    from(e in Event,
      where: e.host_user_id == ^voile_user_id and is_nil(e.deleted_at),
      order_by: [desc: e.starts_at]
    )
    |> Repo.all()
  end

  def list_job_postings_by_user(voile_user_id) do
    from(j in JobPosting,
      where: j.host_user_id == ^voile_user_id,
      order_by: [desc: j.posted_at]
    )
    |> Repo.all()
  end

  def list_blogs_by_user(voile_user_id) do
    from(b in BlogPost,
      where:
        b.voile_user_id == ^voile_user_id and b.status == "published" and is_nil(b.deleted_at),
      order_by: [desc: b.published_at]
    )
    |> Repo.all()
  end

  def list_orgs_followed_by_user(voile_user_id) do
    from(f in OrgPageFollower,
      where: f.voile_user_id == ^voile_user_id,
      join: org in OrgPage,
      on: org.id == f.org_page_id,
      where: is_nil(org.deleted_at),
      select: org,
      order_by: [asc: org.name]
    )
    |> Repo.all()
  end

  def list_collections_for_orgs_by_node_ids(node_ids) when is_list(node_ids) do
    from(c in Collection,
      where: c.unit_id in ^node_ids and c.status == "published" and c.access_level == "public",
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
  end

  def list_events_by_ids(ids) when is_list(ids) do
    from(e in Event,
      where: e.id in ^ids and is_nil(e.deleted_at),
      order_by: [desc: e.starts_at]
    )
    |> Repo.all()
  end

  # ---------------------------------------------------------------------------
  # Crowdfunding Campaigns
  # ---------------------------------------------------------------------------

  def list_active_campaigns(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    offset = (page - 1) * @page_size
    campaign_type = Keyword.get(opts, :campaign_type, nil)
    category = Keyword.get(opts, :category, nil)
    search = Keyword.get(opts, :search, "")

    from(c in CrowdfundingCampaign,
      where: c.status == :active and is_nil(c.deleted_at)
    )
    |> filter_campaigns_by_type(campaign_type)
    |> filter_campaigns_by_category(category)
    |> search_campaigns(search)
    |> order_by([c], desc: c.inserted_at)
    |> limit(@page_size)
    |> offset(^offset)
    |> Repo.all()
  end

  def get_campaign_by_slug(slug) do
    Repo.get_by(CrowdfundingCampaign, slug: slug, status: :active)
  end

  defp filter_campaigns_by_type(query, nil), do: query

  defp filter_campaigns_by_type(query, type) do
    from(c in query, where: c.campaign_type == ^type)
  end

  defp filter_campaigns_by_category(query, nil), do: query

  defp filter_campaigns_by_category(query, category) do
    from(c in query, where: c.category == ^category)
  end

  defp search_campaigns(query, ""), do: query

  defp search_campaigns(query, search) do
    term = "%#{search}%"
    from(c in query, where: ilike(c.title, ^term) or ilike(c.description, ^term))
  end

  # ---------------------------------------------------------------------------
  # Collection Exchange
  # ---------------------------------------------------------------------------

  def list_exchange_offers(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    offset = (page - 1) * @page_size
    search = Keyword.get(opts, :search, "")
    province = Keyword.get(opts, :province, nil)

    from(o in ExchangeOffer,
      where: o.status == :available and is_nil(o.deleted_at)
    )
    |> filter_offers_by_province(province)
    |> search_offers(search)
    |> order_by([o], desc: o.inserted_at)
    |> limit(@page_size)
    |> offset(^offset)
    |> Repo.all()
  end

  def list_exchange_wishlists(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    offset = (page - 1) * @page_size
    search = Keyword.get(opts, :search, "")

    from(w in ExchangeWishlist,
      where: w.status == :open and is_nil(w.deleted_at)
    )
    |> search_wishlists(search)
    |> order_by([w], desc: w.inserted_at)
    |> limit(@page_size)
    |> offset(^offset)
    |> Repo.all()
  end

  defp filter_offers_by_province(query, nil), do: query

  defp filter_offers_by_province(query, province) do
    from(o in query, where: o.available_province == ^province)
  end

  defp search_offers(query, ""), do: query

  defp search_offers(query, search) do
    term = "%#{search}%"

    from(o in query,
      where:
        ilike(o.item_title, ^term) or
          ilike(o.item_type, ^term) or
          ilike(o.suitability_note, ^term)
    )
  end

  defp search_wishlists(query, ""), do: query

  defp search_wishlists(query, search) do
    term = "%#{search}%"

    from(w in query,
      where:
        ilike(w.item_title, ^term) or
          ilike(w.item_type, ^term) or
          ilike(w.subject_area, ^term)
    )
  end
end
