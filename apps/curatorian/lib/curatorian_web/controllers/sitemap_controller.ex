defmodule CuratorianWeb.SitemapController do
  @moduledoc "Serves /sitemap.xml from the cached URL list."

  use CuratorianWeb, :controller

  def show(conn, _params) do
    urls =
      Curatorian.SEO.SitemapCache.urls()
      |> Enum.map(fn url -> %{url | loc: CuratorianWeb.Layouts.absolute_url(url.loc)} end)

    conn
    |> put_layout(false)
    |> put_view(xml: CuratorianWeb.SitemapXML)
    |> put_format(:xml)
    |> put_resp_content_type("application/xml")
    |> render(:sitemap, urls: urls)
  end
end
