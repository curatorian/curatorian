defmodule CuratorianWeb.LayoutComponents do
  use Phoenix.Component
  use Phoenix.LiveComponent
  use Gettext, backend: CuratorianWeb.Gettext

  # alias Phoenix.LiveView.JS

  attr :current_user, :map

  def navigation_header(assigns) do
    assigns =
      assigns
      |> assign_new(:current_user, fn -> nil end)
      |> assign(:menus, [
        %{title: "Beranda", url: "/"},
        %{title: "Tentang", url: "/about"},
        %{title: "Kurator", url: "/kurator"},
        %{title: "Events", url: "/events"}
      ])

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
              <%= for menu <- @menus do %>
                <.link class="nav-link" navigate={menu.url}>
                  {menu.title}
                </.link>
              <% end %>
            </div>
          </div>

          <%= if @current_user do %>
            <div class="hidden lg:block">
              <div class="flex items-center space-x-2">
                <.link href={"/#{@current_user.username}"}>
                  <%= if @current_user.profile.user_image do %>
                    <img
                      src={@current_user.profile.user_image}
                      class="w-8 h-8 object-cover rounded-full"
                      referrerPolicy="no-referrer"
                      alt={@current_user.username}
                    />
                  <% else %>
                    <img
                      src="/images/default.png"
                      class="w-8 h-8 object-cover rounded-full"
                      alt="Default Avatar"
                    />
                  <% end %>
                </.link>
                <.link href="/dashboard" class="btn-primary no-underline text-xs">
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
                <button class="btn-primary bg-violet-1 text-violet-6">Masuk</button>
              </.link>
            </div>
          <% end %>

          <div class="block lg:hidden">
            <button
              class="btn-primary bg-violet-1 text-violet-6 text-lg font-bold"
              id="burger"
              phx-hook="NavbarToggle"
            >
              ☰
            </button>
          </div>
        </div>
        <div
          id="mobile-menu"
          class="lg:hidden hidden h-screen bg-white/90 rounded-xl shadow-md p-6 space-y-4 font-semibold transition-all duration-300"
        >
          <div>
            <button
              class="absolute right-0 pr-6 text-4xl font-bold text-gray-500 "
              id="close-menu"
              aria-label="Close"
              phx-hook="NavbarToggle"
            >
              &times;
            </button>
          </div>
          <div class="flex flex-col space-y-4">
            <%= for menu <- @menus do %>
              <.link
                class="block nav-link hover:font-black transition-all duration-500"
                navigate={menu.url}
              >
                {menu.title}
              </.link>
            <% end %>
          </div>
          <div class="pt-6">
            <%= if @current_user do %>
              <div class="flex flex-col items-center justify-center my-5 gap-3">
                <div class="flex gap-3">
                  <.link href={"/#{@current_user.username}"}>
                    <img
                      src={@current_user.profile.user_image}
                      class="w-12 h-12 object-cover rounded-full"
                      referrerPolicy="no-referrer"
                      alt={@current_user.username}
                    />
                  </.link>
                  <div class="flex flex-col gap-0">
                    <p class="font-semibold">
                      {@current_user.profile.fullname}
                    </p>
                    <.link
                      href={"/#{@current_user.username}"}
                      class="text-xs font-semibold no-underline"
                    >
                      @{@current_user.username}
                    </.link>
                    <p class="text-xs text-gray-400">
                      {@current_user.email}
                    </p>
                  </div>
                </div>
                <div class="flex gap-3">
                  <.link href="/dashboard" class="btn-primary no-underline text-xs">
                    Dashboard
                  </.link>

                  <.link href="/users/log_out" method="delete" class="no-underline btn-cancel text-xs">
                    Log out
                  </.link>
                </div>
              </div>
            <% else %>
              <.link class="no-underline" href="/login">
                <button class="btn-primary bg-violet-1 text-violet-6">Masuk</button>
              </.link>
            <% end %>
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
