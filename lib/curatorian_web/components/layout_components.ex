defmodule CuratorianWeb.LayoutComponents do
  use Phoenix.Component
  use Phoenix.LiveComponent
  use Gettext, backend: CuratorianWeb.Gettext

  # alias Phoenix.LiveView.JS

  attr :current_user, :map

  def navigation_header(assigns) do
    ~H"""
    <header class="fixed w-full p-0 md:p-4 z-100">
      <nav class="p-0 md:p-5">
        <div class="bg-white/90 shadow-xl w-full rounded-xl p-5 flex justify-between items-center transition-all-500">
          <div>
            <p class="font-bold text-2xl">Curatorian</p>
          </div>
          
          <div class="hidden lg:block">
            <ul class="flex space-x-6 font-semibold">
              <li>
                <.link class="no-underline" href="/">
                  Beranda
                </.link>
              </li>
              
              <li>
                <.link class="no-underline cursor-not-allowed" href="/#">
                  Tentang
                </.link>
              </li>
              
              <li>
                <.link class="no-underline cursor-not-allowed" href="/#">
                  Kurator
                </.link>
              </li>
              
              <li>
                <.link class="no-underline cursor-not-allowed" href="/#">
                  Events
                </.link>
              </li>
              
              <li>
                <.link class="no-underline cursor-not-allowed" href="/#">
                  Forum
                </.link>
              </li>
            </ul>
          </div>
          
          <%= if @current_user do %>
            <div class="hidden lg:block">
              <p class="text-[0.8125rem] leading-6 text-zinc-900">
                Halo, {@current_user.username}!
              </p>
              
              <.link class="no-underline" href="/users/log_out">
                Keluar
              </.link>
            </div>
          <% else %>
            <div class="hidden lg:block">
              <.link class="no-underline" href="/login">
                <button class="btn bg-violet-1 text-violet-6">Masuk</button>
              </.link>
            </div>
          <% end %>
          
          <div class="block lg:hidden">
            <button class="btn bg-violet-1 text-violet-6 text-lg font-bold">☰</button>
          </div>
        </div>
      </nav>
    </header>
    """
  end

  def footer_layout(assigns) do
    assigns = assign(assigns, :year, DateTime.utc_now().year)

    ~H"""
    <footer>
      <div class="bg-gray-800 text-white text-center py-10 w-full">
        <p>&copy; {@year} Curatorian ID. All rights reserved.</p>
        
        <p>
          <a
            href="https://www.instagram.com/curatorian_id"
            class="text-white no-underline mx-2 hover:underline"
            target="_blank"
          >
            Instagram
          </a>
          |
          <a
            href="https://www.twitter.com/curatorian_id"
            class="text-white no-underline mx-2 hover:underline"
            target="_blank"
          >
            Twitter
          </a>
          |
          <a
            href="https://github.com/curatorian"
            class="text-white no-underline mx-2 hover:underline"
            target="_blank"
          >
            GitHub
          </a>
        </p>
        
        <p>
          Lead Developer
          <a href="https://github.com/chrisnaadhi" class="text-violet-3">Chrisna Adhi</a>
        </p>
      </div>
    </footer>
    """
  end
end
