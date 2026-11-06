defmodule Curatorian.SEO.Sitemap do
  @moduledoc """
  Builds the list of crawlable URLs served at /sitemap.xml.

  Visibility rules mirror what anonymous visitors can actually render through
  `Curatorian.Public`, so the sitemap never advertises URLs that 404 or
  redirect. Each section degrades independently: if one query fails the rest
  of the sitemap still ships.
  """

  import Ecto.Query
  require Logger

  alias Curatorian.Repo

  alias Curatorian.Public.{
    UserProfile,
    OrgPage,
    NodeProfile,
    Collection,
    BlogPost,
    JobPosting,
    Event,
    CrowdfundingCampaign,
    Guide
  }

  @per_page 500
  @max_urls 10_000

  @static_urls [
    {"/", "daily", 1.0},
    {"/blog", "daily", 0.8},
    {"/kurator", "daily", 0.8},
    {"/orgs", "daily", 0.8},
    {"/collections", "daily", 0.8},
    {"/events", "daily", 0.7},
    {"/jobs", "daily", 0.7},
    {"/crowdfunding", "weekly", 0.6},
    {"/guides", "weekly", 0.7},
    {"/exchange", "weekly", 0.5},
    {"/tools", "weekly", 0.5},
    {"/tools/library", "monthly", 0.4},
    {"/tools/gallery", "monthly", 0.4},
    {"/tools/museum", "monthly", 0.4},
    {"/tools/archive", "monthly", 0.4},
    {"/tools/library/classifications", "monthly", 0.4},
    {"/library/classification", "monthly", 0.4},
    {"/about", "monthly", 0.5},
    {"/roadmap", "monthly", 0.3},
    {"/privacy-policy", "yearly", 0.2}
  ]

  def build do
    static =
      Enum.map(@static_urls, fn {path, freq, priority} ->
        %{loc: path, changefreq: freq, priority: priority, lastmod: nil}
      end)

    static
    |> Enum.concat(dynamic_urls())
    |> Enum.take(@max_urls)
  end

  defp dynamic_urls do
    safe(&profile_urls/0, "profiles") ++
      safe(&org_urls/0, "orgs") ++
      safe(&blog_urls/0, "blog") ++
      safe(&collection_urls/0, "collections") ++
      safe(&event_urls/0, "events") ++
      safe(&job_urls/0, "jobs") ++
      safe(&crowdfunding_urls/0, "crowdfunding") ++
      safe(&guide_urls/0, "guides")
  end

  # /u/:username — publicly listed profiles only
  defp profile_urls do
    fetch_all(fn offset ->
      from(p in UserProfile,
        where: p.is_public == true and is_nil(p.deleted_at),
        order_by: [asc: p.id],
        limit: @per_page,
        offset: ^offset,
        select: %{username: p.username, lastmod: p.updated_at}
      )
      |> Repo.all()
      |> Enum.map(&entry("/u/#{&1.username}", "weekly", 0.6, &1.lastmod))
    end)
  end

  # /orgs/:slug — org page public AND its node profile approved
  defp org_urls do
    fetch_all(fn offset ->
      from(o in OrgPage,
        join: np in NodeProfile,
        on:
          np.voile_node_id == o.voile_node_id and np.status == :approved and is_nil(np.deleted_at),
        where: o.is_public == true and is_nil(o.deleted_at),
        order_by: [asc: o.id],
        limit: @per_page,
        offset: ^offset,
        select: %{slug: o.slug, lastmod: o.updated_at}
      )
      |> Repo.all()
      |> Enum.map(&entry("/orgs/#{&1.slug}", "weekly", 0.6, &1.lastmod))
    end)
  end

  # /u/:username/blog/:slug — published posts from public authors
  defp blog_urls do
    fetch_all(fn offset ->
      from(p in BlogPost,
        join: u in UserProfile,
        on: u.voile_user_id == p.voile_user_id and u.is_public == true and is_nil(u.deleted_at),
        where: p.status == "published" and is_nil(p.deleted_at),
        order_by: [asc: p.id],
        limit: @per_page,
        offset: ^offset,
        select: %{
          username: u.username,
          slug: p.slug,
          lastmod: coalesce(p.published_at, p.updated_at)
        }
      )
      |> Repo.all()
      |> Enum.map(&entry("/u/#{&1.username}/blog/#{&1.slug}", "monthly", 0.6, &1.lastmod))
    end)
  end

  # /collections/:id — published and public
  defp collection_urls do
    fetch_all(fn offset ->
      from(c in Collection,
        where: c.status == "published" and c.access_level == "public",
        order_by: [asc: c.id],
        limit: @per_page,
        offset: ^offset,
        select: %{id: c.id, lastmod: c.updated_at}
      )
      |> Repo.all()
      |> Enum.map(&entry("/collections/#{&1.id}", "monthly", 0.5, &1.lastmod))
    end)
  end

  # /events/:slug — only events the show page actually serves
  # (published/ongoing and not in the past), mirroring get_event_by_slug/1.
  defp event_urls do
    now = DateTime.utc_now()

    fetch_all(fn offset ->
      from(e in Event,
        where:
          is_nil(e.deleted_at) and
            e.status in [:published, :ongoing] and
            (e.starts_at >= ^now or e.status == :ongoing),
        order_by: [asc: e.id],
        limit: @per_page,
        offset: ^offset,
        select: %{slug: e.slug, lastmod: e.updated_at}
      )
      |> Repo.all()
      |> Enum.map(&entry("/events/#{&1.slug}", "daily", 0.7, &1.lastmod))
    end)
  end

  # /jobs/:slug — active postings only
  defp job_urls do
    fetch_all(fn offset ->
      from(j in JobPosting,
        where: j.status == :active and is_nil(j.deleted_at),
        order_by: [asc: j.id],
        limit: @per_page,
        offset: ^offset,
        select: %{slug: j.slug, lastmod: coalesce(j.posted_at, j.updated_at)}
      )
      |> Repo.all()
      |> Enum.map(&entry("/jobs/#{&1.slug}", "daily", 0.7, &1.lastmod))
    end)
  end

  # /crowdfunding/:slug — active campaigns only
  defp crowdfunding_urls do
    fetch_all(fn offset ->
      from(c in CrowdfundingCampaign,
        where: c.status == :active and is_nil(c.deleted_at),
        order_by: [asc: c.id],
        limit: @per_page,
        offset: ^offset,
        select: %{slug: c.slug, lastmod: c.updated_at}
      )
      |> Repo.all()
      |> Enum.map(&entry("/crowdfunding/#{&1.slug}", "weekly", 0.6, &1.lastmod))
    end)
  end

  # /guides/:slug — published guides only
  defp guide_urls do
    fetch_all(fn offset ->
      from(g in Guide,
        where: g.status == "published" and is_nil(g.deleted_at),
        order_by: [asc: g.id],
        limit: @per_page,
        offset: ^offset,
        select: %{slug: g.slug, lastmod: coalesce(g.published_at, g.updated_at)}
      )
      |> Repo.all()
      |> Enum.map(&entry("/guides/#{&1.slug}", "monthly", 0.6, &1.lastmod))
    end)
  end

  defp fetch_all(runner) do
    0
    |> Stream.unfold(fn offset ->
      case runner.(offset) do
        [] -> nil
        rows -> {rows, offset + @per_page}
      end
    end)
    |> Enum.flat_map(& &1)
  end

  defp entry(loc, changefreq, priority, lastmod) do
    %{loc: loc, changefreq: changefreq, priority: priority, lastmod: date(lastmod)}
  end

  defp date(nil), do: nil
  defp date(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d")
  defp date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d")
  defp date(dt) when is_binary(dt), do: binary_part(dt, 0, min(10, byte_size(dt)))

  defp safe(fun, section) do
    fun.()
  rescue
    e ->
      Logger.error("Sitemap section '#{section}' failed: #{Exception.message(e)}")
      []
  end
end
