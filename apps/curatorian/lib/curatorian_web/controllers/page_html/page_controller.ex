defmodule CuratorianWeb.PageController do
  use CuratorianWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    conn
    |> assign(:page_title, "Curatorian — Komunitas Pengelola Koleksi GLAM Indonesia")
    |> assign(:json_ld, home_json_ld())
    |> render(:home)
  end

  defp home_json_ld do
    base = CuratorianWeb.Layouts.meta_base_url()

    [
      %{
        "@context" => "https://schema.org",
        "@type" => "WebSite",
        "name" => "Curatorian",
        "url" => base,
        "potentialAction" => %{
          "@type" => "SearchAction",
          "target" => %{
            "@type" => "EntryPoint",
            "urlTemplate" => base <> "/collections?q={search_term_string}"
          },
          "query-input" => "required name=search_term_string"
        }
      },
      %{
        "@context" => "https://schema.org",
        "@type" => "Organization",
        "name" => "Curatorian",
        "url" => base,
        "logo" => base <> "/images/icon.png",
        "sameAs" => [
          "https://www.instagram.com/curatorian_id",
          "https://www.twitter.com/curatorian_id",
          "https://github.com/curatorian"
        ]
      }
    ]
  end

  def about(conn, _) do
    conn
    |> assign(:page_title, "Tentang Curatorian")
    |> assign(
      :og_description,
      "Mengenal Curatorian — jaringan komunitas para pengelola dan kurator koleksi: " <>
        "pustakawan, arsiparis, pengelola museum, galeri, dan TBM di Indonesia."
    )
    |> render(:about)
  end

  def roadmap(conn, _) do
    conn
    |> assign(:page_title, "Roadmap Curatorian")
    |> assign(
      :og_description,
      "Rencana pengembangan fitur Curatorian: manajemen koleksi digital, profil lembaga, " <>
        "event komunitas, lowongan kerja, dan crowdfunding."
    )
    |> render(:roadmap)
  end

  def privacy_policy(conn, _) do
    conn
    |> assign(:page_title, "Kebijakan Privasi")
    |> assign(
      :og_description,
      "Bagaimana Curatorian mengumpulkan, menggunakan, dan melindungi data pribadi Anda."
    )
    |> render(:privacy_policy)
  end

  def library_classification(conn, _) do
    conn
    |> assign(:page_title, "Klasifikasi Perpustakaan")
    |> assign(
      :og_description,
      "Referensi sistem klasifikasi perpustakaan (DDC, UDC, LCC) untuk membantu pengelolaan " <>
        "dan katalogisasi koleksi."
    )
    |> render(:klasifikasi)
  end

  def redirect_manage(conn, _params) do
    redirect(conn, to: "/dashboard")
  end
end
