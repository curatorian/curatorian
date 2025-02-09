defmodule CuratorianWeb.LayoutComponents do
  use Phoenix.Component
  use Phoenix.LiveComponent
  use Gettext, backend: CuratorianWeb.Gettext

  # alias Phoenix.LiveView.JS

  attr :current_user, :map

  def navigation_header(assigns) do
    ~H"""
    <header class="fixed w-full z-40">
      <nav class="p-0 md:p-5">
        <div
          class="bg-white/90 shadow-xl w-full md:rounded-xl p-5 flex justify-between items-center transition-all-500"
          id="navbar"
          phx-hook="NavbarScroll"
        >
          <div>
            <.link class="nav-link font-bold text-2xl" href="/">Curatorian</.link>
          </div>
          
          <div class="hidden lg:block">
            <div class="flex space-x-6 font-semibold">
              <.link class="nav-link" href="/">
                Beranda
              </.link>
              
              <.link class="nav-link" href="/#">
                Tentang
              </.link>
              
              <.link class="nav-link" href="/#">
                Kurator
              </.link>
              
              <.link class="nav-link" href="/#">
                Events
              </.link>
              
              <.link class="nav-link" href="/#">
                Forum
              </.link>
            </div>
          </div>
          
          <%= if @current_user do %>
            <div class="hidden lg:block">
              <div class="flex items-center space-x-2">
                <img
                  src={@current_user.profile.user_image}
                  class="w-8 h-8 object-cover rounded-full"
                  referrerPolicy="no-referrer"
                  alt={@current_user.username}
                />
                <.link href="/dashboard" class="btn no-underline text-xs">
                  Dashboard
                </.link>
                
                <.link href="/users/log_out" method="delete" class="no-underline btn-cancel text-xs">
                  Log out
                </.link>
              </div>
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
          <a href="https://github.com/chrisnaadhi" class="text-violet-3" target="_blank">
            Chrisna Adhi
          </a>
        </p>
      </div>
    </footer>
    """
  end
end
