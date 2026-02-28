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
    first_feature_list = [
      %{
        title: "Profil",
        description:
          "Berisi profil dan detail biodata dari profesional kurator, tenaga teknis pengelolaan koleksi, fresh graduate maupun mahasiswa.",
        icon: "hero-user-circle-solid",
        status: "active"
      },
      %{
        title: "Profil Lembaga",
        description:
          "Halaman profil dari lembaga, asosiasi, forum maupun organisasi tempat bekerja atau berkarya.",
        icon: "hero-building-library-solid",
        status: "soon"
      },
      %{
        title: "Kegiatan & Acara",
        description:
          "Membuat dan membagikan kegiatan serta event yang berkaitan dengan kurasi koleksi.",
        icon: "hero-calendar-days-solid",
        status: "soon"
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
        status: "soon"
      },
      %{
        title: "Forum",
        description:
          "Memberikan fitur bagi pengguna untuk berkomunikasi dalam bentuk grup (kanal) maupun personal.",
        icon: "hero-chat-bubble-left-right-solid",
        status: "soon"
      },
      %{
        title: "Courses",
        description:
          "Memberikan fitur bagi pengguna untuk mengikuti kursus, workshop, seminar, dan pelatihan.",
        icon: "hero-academic-cap-solid",
        status: "soon"
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

            <div class="mt-2">
              <span class={[
                "text-xs py-1 px-2 rounded-full",
                feature.status == "active" && "bg-green-500 text-white",
                feature.status == "soon" && "bg-gray-200 text-violet-600"
              ]}>
                {String.capitalize(feature.status)}
              </span>
            </div>
          </div>
        <% end %>
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
          <p class="py-5">Silahkan masukkan E-Mail pengingat untuk informasi rilis Curatorian</p>

          <div class="flex gap-2 max-w-2xl ma w-full">
            <input
              type="email"
              name="email"
              id="email"
              placeholder="Email Anda"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-violet-500"
            /> <button type="submit" class="btn-primary bg-violet-5 text-white">Ingatkan</button>
          </div>

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
                  href="https://discord.gg/CS6pYuVwZa"
                  target="_blank"
                  aria-label="Discord"
                  title="Discord Curatorian"
                >
                  <svg
                    width="2em"
                    height="2em"
                    viewBox="0 0 1024 1024"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="#000000"
                  >
                    <g id="SVGRepo_bgCarrier" stroke-width="0"></g>

                    <g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g>

                    <g id="SVGRepo_iconCarrier">
                      <circle cx="512" cy="512" r="512" style="fill:#5865f2"></circle>

                      <path
                        d="M689.43 349a422.21 422.21 0 0 0-104.22-32.32 1.58 1.58 0 0 0-1.68.79 294.11 294.11 0 0 0-13 26.66 389.78 389.78 0 0 0-117.05 0 269.75 269.75 0 0 0-13.18-26.66 1.64 1.64 0 0 0-1.68-.79A421 421 0 0 0 334.44 349a1.49 1.49 0 0 0-.69.59c-66.37 99.17-84.55 195.9-75.63 291.41a1.76 1.76 0 0 0 .67 1.2 424.58 424.58 0 0 0 127.85 64.63 1.66 1.66 0 0 0 1.8-.59 303.45 303.45 0 0 0 26.15-42.54 1.62 1.62 0 0 0-.89-2.25 279.6 279.6 0 0 1-39.94-19 1.64 1.64 0 0 1-.16-2.72c2.68-2 5.37-4.1 7.93-6.22a1.58 1.58 0 0 1 1.65-.22c83.79 38.26 174.51 38.26 257.31 0a1.58 1.58 0 0 1 1.68.2c2.56 2.11 5.25 4.23 8 6.24a1.64 1.64 0 0 1-.14 2.72 262.37 262.37 0 0 1-40 19 1.63 1.63 0 0 0-.87 2.28 340.72 340.72 0 0 0 26.13 42.52 1.62 1.62 0 0 0 1.8.61 423.17 423.17 0 0 0 128-64.63 1.64 1.64 0 0 0 .67-1.18c10.68-110.44-17.88-206.38-75.7-291.42a1.3 1.3 0 0 0-.63-.63zM427.09 582.85c-25.23 0-46-23.16-46-51.6s20.38-51.6 46-51.6c25.83 0 46.42 23.36 46 51.6.02 28.44-20.37 51.6-46 51.6zm170.13 0c-25.23 0-46-23.16-46-51.6s20.38-51.6 46-51.6c25.83 0 46.42 23.36 46 51.6.01 28.44-20.17 51.6-46 51.6z"
                        style="fill:#fff"
                      >
                      </path>
                    </g>
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
end
