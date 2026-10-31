defmodule CuratorianWeb.HomepageComponents do
  use Phoenix.Component
  use Phoenix.LiveComponent
  use Gettext, backend: CuratorianWeb.Gettext

  import CuratorianWeb.CoreComponents

  def apa_itu_curatorian(assigns) do
    ~H"""
    <div class="relative">
      <div class="absolute w-full flex items-center justify-center">
        <img
          src="/images/undraw_questions.png"
          class="w-full max-w-xl h-full opacity-15"
          alt="questions"
        />
      </div>

      <div class="relative text-center pt-20 z-10">
        <h2>Apa itu Curatorian ?</h2>

        <h6 class="pt-3 italic">(abbr) Curator's Information Associated Network</h6>

        <p class="max-w-3xl mx-auto py-10 px-5 text-justify">
          Curatorian merupakan sebuah situs dan portal berbasis komunitas dimana seluruh lapisan masyarakat yang berprofesi atau memiliki ketertarikan dalam melakukan kurasi koleksi dapat berkumpul dan berbagi bersama mengenai profil identitas, hasil kurasi koleksi, kegiatan, acara serta pengalaman. Inisiasi ini dibentuk untuk memberikan wadah bagi para profesional, pendidik maupun pembelajar untuk berbagi pengalaman sebagai seorang profesional pengelola koleksi serta pengetahuan.
        </p>
      </div>
    </div>
    """
  end

  def kenapa_harus_curatorian(assigns) do
    ~H"""
    <div class="py-20 px-5 flex flex-col lg:grid lg:grid-cols-2 items-center justify-around max-w-5xl mx-auto">
      <div class="flex items-center justify-center lg:order-first">
        <img
          src="/images/undraw_lightbulb-moment.png"
          class="max-w-sm h-full"
          alt="Kenapa Curatorian"
        />
      </div>

      <div>
        <h3 class="text-center md:text-left py-5">Kenapa harus Curatorian ?</h3>

        <p class="text-justify">
          Curatorian dibuat dan diinisiasi untuk memenuhi kebutuhan komunitas terhadap suatu media yang mampu memberikan jalan bagi setiap orang yang berprofesi di bidang kurasi koleksi seperti Pustakawan, Arsiparis, Pengelola Records, Ahli Museum, Kurator Galeri, Botanist dan kurator koleksi & pengetahuan lainnya untuk dapat berbagi informasi mengenai profesionalisme di bidangnya masing-masing. Tujuan utama dibuat Curatorian adalah untuk mendukung kolaborasi efektif dengan para profesional, pendidik serta pembelajar dalam mengelola koleksi serta berbagi pengetahuan.
        </p>
      </div>
    </div>
    """
  end

  def cara_kerja_curatorian(assigns) do
    ~H"""
    <div class="py-20 px-5 flex flex-col lg:grid lg:grid-cols-2 items-center justify-around max-w-5xl mx-auto">
      <div class="flex items-center justify-center lg:order-last">
        <img
          src="/images/undraw_solution-mindset.png"
          class="max-w-sm h-full"
          alt="Kenapa Curatorian"
        />
      </div>

      <div>
        <h3 class="text-center md:text-left py-5">Cara Kerja Curatorian ?</h3>

        <p class="text-justify">
          Curatorian akan memberikan berbagai fitur bagi penggunanya untuk membuat profil mereka masing-masing (seperti Linkedin), membangun halaman profil dari lembaga dan organisasi tempat mereka bekerja atau berkarya (seperti halaman Facebook), membuat dan membagikan kegiatan serta event yang berkaitan dengan kurasi koleksi (Event Organization), serta berbagi pengalaman dan pengetahuan yang dimiliki. Untuk mempermudah koneksi dan kolaborasi, Curatorian juga akan memberikan fitur Kolaborasi Projek (Upwork / Freelance) serta Daftar Lowongan Kerja (seperti Glints).
        </p>
      </div>
    </div>
    """
  end

  def fitur_utama_curatorian(assigns) do
    assigns = assign_new(assigns, :current_scope, fn -> nil end)

    atrium_url =
      System.get_env("ATRIUM_URL") ||
        Application.get_env(:curatorian, :atrium_url, "http://localhost:4001") <> "/dashboard"

    cta_url =
      if assigns.current_scope && assigns.current_scope.user do
        atrium_url
      else
        "/register"
      end

    cta_text =
      if assigns.current_scope && assigns.current_scope.user do
        "Buka Dashboard"
      else
        "Mulai Gratis"
      end

    assigns =
      assigns
      |> assign(:cta_url, cta_url)
      |> assign(:cta_text, cta_text)

    first_feature_list = [
      %{
        title: "Profil",
        description:
          "Berisi profil dan detail biodata dari profesional kurator, tenaga teknis pengelolaan koleksi, fresh graduate maupun mahasiswa.",
        icon: "hero-user-circle-solid",
        status: "active",
        url: "/register"
      },
      %{
        title: "Profil Lembaga",
        description:
          "Halaman profil dari lembaga, asosiasi, forum maupun organisasi tempat bekerja atau berkarya.",
        icon: "hero-building-library-solid",
        status: "active",
        url: "/orgs"
      },
      %{
        title: "Kegiatan & Acara",
        description:
          "Membuat dan membagikan kegiatan serta event yang berkaitan dengan kurasi koleksi.",
        icon: "hero-calendar-days-solid",
        status: "active",
        url: "/events"
      }
    ]

    second_feature_list = [
      %{
        title: "Kolaborasi Projek",
        image:
          "Fitur untuk melakukan kolaborasi projek dengan para profesional, pendidik serta pembelajar.",
        status: "soon"
      },
      %{
        title: "Lowongan Kerja",
        image: "Fitur untuk mencari dan membagikan lowongan pekerjaan di bidang kurasi koleksi.",
        status: "soon"
      },
      %{
        title: "Live Chat & Voice Chat",
        image:
          "Fitur untuk melakukan live chat dan voice chat dengan seluruh user dalam bentuk grup (kanal) maupun personal.",
        status: "soon"
      }
    ]

    third_feature_list = [
      %{
        title: "Job Boards",
        description:
          "Memberikan fitur bagi pengguna untuk mencari dan menawarkan lowongan kerja di bidang kurasi koleksi.",
        icon: "hero-briefcase-solid",
        status: "active",
        url: "/jobs"
      },
      %{
        title: "Forum",
        description:
          "Memberikan fitur bagi pengguna untuk berkomunikasi dalam bentuk grup (kanal) maupun personal.",
        icon: "hero-chat-bubble-left-right-solid",
        status: "active",
        url: "/register"
      },
      %{
        title: "Crowdfunding",
        description:
          "Menyediakan fitur crowdfunding untuk mendanai proyek-proyek kurasi koleksi. Tidak hanya dalam bentuk uang,
          tetapi juga koleksi, tenaga kerja, dan kolaborasi.",
        icon: "hero-heart-solid",
        status: "active",
        url: "/crowdfunding"
      }
    ]

    assigns =
      assigns
      |> assign(:first_feature_list, first_feature_list)
      |> assign(:second_feature_list, second_feature_list)
      |> assign(:third_feature_list, third_feature_list)

    ~H"""
    <div class="text-center max-w-5xl mx-auto px-5">
      <h3>Fitur Utama dari Curatorian</h3>

      <div class="flex flex-col md:grid md:grid-cols-2) lg:grid-cols-3 gap-5 py-10">
        <%= for feature <- @first_feature_list do %>
          <div class="bg-white dark:bg-gray-700 p-8 rounded-lg flex flex-col items-center justify-between">
            <div>
              <.icon name={feature.icon} class="text-violet-500 h-16 w-16" />
              <h4 class="py-1 text-violet-500">{feature.title}</h4>

              <p class="text-gray-600 dark:text-white text-sm italic">{feature.description}</p>
            </div>

            <div class="my-2">
              <span class={[
                "text-xs py-1 px-2 rounded-full",
                feature.status == "active" && "bg-green-500 text-white",
                feature.status == "soon" && "bg-gray-200 text-violet-600"
              ]}>
                {String.capitalize(feature.status)}
              </span>
            </div>

            <div class="w-full text-xs my-2">
              <.link navigate={feature.url}>
                Lihat &rightarrow;
              </.link>
            </div>
          </div>
        <% end %>
      </div>

      <div class="relative bg-gradient-to-br from-violet-600 to-purple-700 rounded-2xl p-10 my-6 overflow-hidden text-white shadow-xl">
        <%!-- Decorative background rings --%>
        <div class="absolute -top-12 -right-12 w-56 h-56 rounded-full bg-white/5"></div>
        <div class="absolute -bottom-16 -left-16 w-72 h-72 rounded-full bg-white/5"></div>

        <div class="relative z-10 flex flex-col lg:flex-row items-center gap-8">
          <div class="w-16 h-16 rounded-2xl bg-white/15 flex items-center justify-center shrink-0">
            <.icon name="hero-archive-box-solid" class="w-8 h-8 text-white" />
          </div>

          <div class="text-center lg:text-left flex-1">
            <p class="text-xs font-semibold uppercase tracking-widest text-violet-200 mb-2">
              Fitur Utama
            </p>
            <h4 class="text-xl md:text-2xl font-bold mb-3">
              Manajemen Koleksi Digital Berbasis GLAM
            </h4>
            <p class="text-sm md:text-base text-violet-100 leading-relaxed max-w-2xl">
              Menyediakan fitur manajemen koleksi berbasis GLAM dalam bentuk digital untuk
              memudahkan pengguna dalam mengelola koleksi termasuk katalogisasi, pelacakan,
              dan pemeliharaan koleksi.
            </p>
            <p class="text-xs italic">
              Berbasis
              <a
                href="https://github.com/curatorian/voile"
                class="!text-violet-200 hover:underline"
                target="_blank"
              >
                Voile, the Magic Library
              </a>
              yang merupakan sistem pengelolaan koleksi berbasis
              GLAM yang open source dan sudah digunakan oleh Universitas Padjadjaran untuk mengelola
              koleksi akademik, penelitian dan warisan budaya.
            </p>
          </div>

          <a
            href={@cta_url}
            class="shrink-0 inline-flex items-center gap-2 bg-white text-violet-700 font-semibold text-sm px-6 py-3 rounded-xl hover:bg-violet-50 transition-colors shadow-md"
            target={if(@current_scope && @current_scope.user, do: "_blank", else: nil)}
            rel={if(@current_scope && @current_scope.user, do: "noreferrer noopener", else: nil)}
          >
            {@cta_text} <.icon name="hero-arrow-right" class="w-4 h-4" />
          </a>
        </div>
      </div>

      <div class="flex flex-col md:grid md:grid-cols-2) lg:grid-cols-3 gap-5 py-10">
        <%= for feature <- @third_feature_list do %>
          <div class="bg-white dark:bg-gray-700 p-8 rounded-lg flex flex-col items-center justify-between">
            <div>
              <.icon name={feature.icon} class="text-violet-500 h-16 w-16" />
              <h4 class="py-1 text-violet-500">{feature.title}</h4>

              <p class="text-gray-600 dark:text-white text-sm italic">{feature.description}</p>
            </div>

            <div class="mt-2">
              <span class={[
                "text-xs py-1 px-2 rounded-full",
                feature.status == "active" && "bg-green-500 text-white",
                feature.status == "soon" && "bg-gray-200 text-violet-600"
              ]}>
                {String.capitalize(feature.status)}
              </span>
            </div>

            <div class="w-full text-xs my-2">
              <.link navigate={feature.url}>
                Lihat &rightarrow;
              </.link>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def tertarik_dengan_curatorian(assigns) do
    ~H"""
    <div class="text-center max-w-5xl py-20 px-5 mx-auto">
      <h3 class="mb-10">Tertarik dengan Curatorian ?</h3>

      <div class="flex flex-col md:flex-row items-center justify-center w-full gap-5">
        <div><img src="/images/undraw_referral.png" class="w-full max-w-md" alt="" /></div>

        <div>
          <div class="pt-5">
            <h6>Ikut Media Sosial Kami :</h6>

            <div>
              <div class="flex items-center justify-center gap-5 pt-5">
                <a
                  href="https://instagram.com/curatorian_id"
                  target="_blank"
                  aria-label="Instagram"
                  title="Instagram Curatorian"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="2em" height="2em" viewBox="0 0 24 24">
                    <path
                      fill="#962fbf"
                      d="M7.8 2h8.4C19.4 2 22 4.6 22 7.8v8.4a5.8 5.8 0 0 1-5.8 5.8H7.8C4.6 22 2 19.4 2 16.2V7.8A5.8 5.8 0 0 1 7.8 2m-.2 2A3.6 3.6 0 0 0 4 7.6v8.8C4 18.39 5.61 20 7.6 20h8.8a3.6 3.6 0 0 0 3.6-3.6V7.6C20 5.61 18.39 4 16.4 4zm9.65 1.5a1.25 1.25 0 0 1 1.25 1.25A1.25 1.25 0 0 1 17.25 8A1.25 1.25 0 0 1 16 6.75a1.25 1.25 0 0 1 1.25-1.25M12 7a5 5 0 0 1 5 5a5 5 0 0 1-5 5a5 5 0 0 1-5-5a5 5 0 0 1 5-5m0 2a3 3 0 0 0-3 3a3 3 0 0 0 3 3a3 3 0 0 0 3-3a3 3 0 0 0-3-3"
                    />
                  </svg>
                </a>
                <a
                  href="https://twitter.com/curatorian_id"
                  target="_blank"
                  aria-label="Twitter"
                  title="Twitter Curatorian"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="2em" height="2em" viewBox="0 0 24 24">
                    <path
                      fill="#1DA1F2"
                      d="M22.46 6c-.77.35-1.6.58-2.46.69c.88-.53 1.56-1.37 1.88-2.38c-.83.5-1.75.85-2.72 1.05C18.37 4.5 17.26 4 16 4c-2.35 0-4.27 1.92-4.27 4.29c0 .34.04.67.11.98C8.28 9.09 5.11 7.38 3 4.79c-.37.63-.58 1.37-.58 2.15c0 1.49.75 2.81 1.91 3.56c-.71 0-1.37-.2-1.95-.5v.03c0 2.08 1.48 3.82 3.44 4.21a4.2 4.2 0 0 1-1.93.07a4.28 4.28 0 0 0 4 2.98a8.52 8.52 0 0 1-5.33 1.84q-.51 0-1.02-.06C3.44 20.29 5.7 21 8.12 21C16 21 20.33 14.46 20.33 8.79c0-.19 0-.37-.01-.56c.84-.6 1.56-1.36 2.14-2.23"
                    />
                  </svg>
                </a>
                <a
                  href="https://github.com/curatorian"
                  target="_blank"
                  aria-label="Github"
                  title="Github Curatorian"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="2em" height="2em" viewBox="0 0 24 24">
                    <path
                      fill="#000"
                      d="M12 2A10 10 0 0 0 2 12c0 4.42 2.87 8.17 6.84 9.5c.5.08.66-.23.66-.5v-1.69c-2.77.6-3.36-1.34-3.36-1.34c-.46-1.16-1.11-1.47-1.11-1.47c-.91-.62.07-.6.07-.6c1 .07 1.53 1.03 1.53 1.03c.87 1.52 2.34 1.07 2.91.83c.09-.65.35-1.09.63-1.34c-2.22-.25-4.55-1.11-4.55-4.92c0-1.11.38-2 1.03-2.71c-.1-.25-.45-1.29.1-2.64c0 0 .84-.27 2.75 1.02c.79-.22 1.65-.33 2.5-.33s1.71.11 2.5.33c1.91-1.29 2.75-1.02 2.75-1.02c.55 1.35.2 2.39.1 2.64c.65.71 1.03 1.6 1.03 2.71c0 3.82-2.34 4.66-4.57 4.91c.36.31.69.92.69 1.85V21c0 .27.16.59.67.5C19.14 20.16 22 16.42 22 12A10 10 0 0 0 12 2"
                    />
                  </svg>
                </a>
                <a
                  href="https://chat.whatsapp.com/KwtJKSeNHSX4jYmFMjD9wv"
                  target="_blank"
                  rel="noreferrer"
                  aria-label="WhatsApp"
                  title="Komunitas WhatsApp Curatorian"
                >
                  <svg
                    width="2em"
                    height="2em"
                    viewBox="0 0 448 512"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="#000000"
                  >
                    <path
                      d="M380.9 97.1C339 55.1 283.2 32 223.9 32c-122.4 0-222 99.6-222 222 0 39.1 10.2 77.3 29.6 111L0 480l117.7-30.9c32.4 17.7 68.9 27 106.1 27h.1c122.3 0 224.1-99.6 224.1-222 0-59.3-25.2-115-67.1-157zm-157 341.6c-33.2 0-65.7-8.9-94-25.7l-6.7-4-69.8 18.3L72 359.2l-4.4-7c-18.5-29.4-28.2-63.3-28.2-98.2 0-101.7 82.8-184.5 184.6-184.5 49.3 0 95.6 19.2 130.4 54.1 34.8 34.9 56.2 81.2 56.1 130.5 0 101.8-84.9 184.6-186.6 184.6zm101.2-138.2c-5.5-2.8-32.8-16.2-37.9-18-5.1-1.9-8.8-2.8-12.5 2.8-3.7 5.6-14.3 18-17.6 21.8-3.2 3.7-6.5 4.2-12 1.4-32.6-16.3-54-29.1-75.5-66-5.7-9.8 5.7-9.1 16.3-30.3 1.8-3.7.9-6.9-.5-9.7-1.4-2.8-12.5-30.1-17.1-41.2-4.5-10.8-9.1-9.3-12.5-9.5-3.2-.2-6.9-.2-10.6-.2-3.7 0-9.7 1.4-14.8 6.9-5.1 5.6-19.4 19-19.4 46.3 0 27.3 19.9 53.7 22.6 57.4 2.8 3.7 39.1 59.7 94.8 83.8 35.2 15.2 49 16.5 66.6 13.9 10.7-1.6 32.8-13.4 37.4-26.4 4.6-13 4.6-24.1 3.2-26.4-1.3-2.5-5-3.9-10.5-6.6z"
                    />
                  </svg>
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ── Metadata standards (GLAM badges) ──────────────────────────────────────
  # Each standard is tagged with the GLAM sector(s) it serves:
  #   g = Gallery, l = Library, a = Archive, m = Museum
  @glam_legend [
    {"g", "Gallery"},
    {"l", "Library"},
    {"a", "Archive"},
    {"m", "Museum"}
  ]

  @glam_badge_classes %{
    "g" =>
      "bg-pink-100 text-pink-700 border-pink-200 dark:bg-pink-900/30 dark:text-pink-300 dark:border-pink-800",
    "l" =>
      "bg-blue-100 text-blue-700 border-blue-200 dark:bg-blue-900/30 dark:text-blue-300 dark:border-blue-800",
    "a" =>
      "bg-emerald-100 text-emerald-700 border-emerald-200 dark:bg-emerald-900/30 dark:text-emerald-300 dark:border-emerald-800",
    "m" =>
      "bg-amber-100 text-amber-700 border-amber-200 dark:bg-amber-900/30 dark:text-amber-300 dark:border-amber-800"
  }

  @glam_labels %{"g" => "Gallery", "l" => "Library", "a" => "Archive", "m" => "Museum"}

  @metadata_standards [
    {"dcterms", "Dublin Core Terms", ~w(g l a m)},
    {"dctype", "Dublin Core Type", ~w(g l a m)},
    {"bibo", "Bibliographic Ontology", ~w(l)},
    {"foaf", "Friend of a Friend", ~w(g l a m)},
    {"vra", "VRA Core", ~w(g)},
    {"cdwalite", "CDWA Lite", ~w(g m)},
    {"exif", "EXIF", ~w(g)},
    {"iptc", "IPTC Photo Metadata", ~w(g)},
    {"xmp", "XMP", ~w(g)},
    {"schema", "Schema.org", ~w(g l a m)},
    {"marc21", "MARC 21", ~w(l)},
    {"mods", "MODS", ~w(l)},
    {"bf", "BIBFRAME", ~w(l)},
    {"mets", "METS", ~w(l a)},
    {"onix", "ONIX", ~w(l)},
    {"isadg", "ISAD(G)", ~w(a)},
    {"ead", "EAD", ~w(a)},
    {"eaccpf", "EAC-CPF", ~w(a)},
    {"ric", "Records in Contexts (RiC)", ~w(a)},
    {"premis", "PREMIS", ~w(a l)},
    {"isaar", "ISAAR(CPF)", ~w(a)},
    {"crm", "CIDOC CRM", ~w(m)},
    {"spectrum", "SPECTRUM", ~w(m)},
    {"lido", "LIDO", ~w(m g)},
    {"objectid", "ICOM Object ID", ~w(m)},
    {"edm", "Europeana Data Model", ~w(g l a m)},
    {"skos", "SKOS", ~w(g l a m)},
    {"iiif", "IIIF Presentation API", ~w(g l a m)}
  ]

  @doc """
  Renders the supported metadata-standards grid with GLAM-sector badges,
  used on the /about page ("Standar Metadata" section).
  """
  attr :class, :string, default: nil

  def metadata_standards(assigns) do
    assigns =
      assigns
      |> assign(:standards, @metadata_standards)
      |> assign(:legend, @glam_legend)
      |> assign(:badge_classes, @glam_badge_classes)
      |> assign(:labels, @glam_labels)

    ~H"""
    <div class={@class}>
      <%!-- Legend --%>
      <div class="flex flex-wrap justify-center gap-2 mb-6">
        <span
          :for={{code, label} <- @legend}
          class={
            "inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full border text-xs font-medium " <>
              Map.get(@badge_classes, code)
          }
        >
          <span class="font-bold uppercase">{code}</span>{label}
        </span>
      </div>

      <div class="max-w-4xl mx-auto grid grid-cols-2 sm:grid-cols-3 gap-3 text-sm text-gray-600 dark:text-gray-300">
        <div
          :for={{prefix, name, glam} <- @standards}
          class="border border-gray-200 dark:border-gray-700 rounded-lg p-3 bg-white dark:bg-gray-900"
        >
          <div class="flex items-start justify-between gap-2">
            <code class="font-mono text-violet-600 dark:text-violet-400">{prefix}</code>
            <div class="flex gap-1 shrink-0">
              <span
                :for={g <- glam}
                title={Map.get(@labels, g)}
                class={
                  "inline-flex items-center justify-center size-5 rounded text-[10px] font-bold uppercase border " <>
                    Map.get(@badge_classes, g)
                }
              >
                {g}
              </span>
            </div>
          </div>
          <p class="mt-1 text-xs text-gray-500 dark:text-gray-400 leading-snug">{name}</p>
        </div>
      </div>
    </div>
    """
  end
end
