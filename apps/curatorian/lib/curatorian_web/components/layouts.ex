defmodule CuratorianWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use CuratorianWeb, :controller` and
  `use CuratorianWeb, :live_view`.
  """
  use CuratorianWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  # MOVED: attr declarations must come immediately before the function
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :current_path, :string, default: nil, doc: "the current request path"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <%= if assigns[:current_scope] do %>
      <.navigation_header current_user={@current_scope.user} />
    <% else %>
      <.navigation_header />
    <% end %>

    <main>
      <.flash_group flash={@flash} />
      <div class="absolute top-0 w-full">
        <img src="/images/lib.webp" alt="hero img" class="relative w-full h-40 object-cover" />
        <div class="absolute top-0 bg-black/80 w-full h-40"></div>

        <div class="absolute bottom-0 w-full h-12 bg-gradient-to-t from-violet-100 dark:from-gray-600 to-transparent">
        </div>
      </div>

      <%= if @current_path === "/" do %>
        <section class="min-h-screen h-full bg-violet-100 dark:bg-gray-600">
          {render_slot(@inner_block)}
        </section>
      <% else %>
        <section class="pt-48 px-5 min-h-screen h-full bg-violet-100 dark:bg-gray-600">
          {render_slot(@inner_block)}
        </section>
      <% end %>

      <%!-- <section class="pt-48 min-h-screen h-full bg-violet-100 dark:bg-gray-600">
          {render_slot(@inner_block)}}
        </section> --%>
    </main>
    <.footer_layout /> <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} /> <.flash kind={:error} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0
        [[data-theme-pref=light]_&]:left-1/3
        [[data-theme-pref=dark]_&]:left-2/3
        transition-[left]" />
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  attr :current_user, :map, default: nil

  def navigation_header(assigns) do
    assigns =
      assigns
      |> assign_new(:current_user, fn -> nil end)
      |> assign(:menus, [
        %{title: "Beranda", url: "/"},
        %{title: "Tentang", url: "/about"},
        %{title: "Kurator", url: "/kurator"},
        %{title: "Organisasi", url: "/orgs"},
        %{title: "Events", url: "/events"}
      ])

    ~H"""
    <header class="fixed w-full z-40">
      <nav class="p-0 md:p-5">
        <div
          class="bg-white/90 dark:bg-gray-800/90 shadow-xl w-full md:rounded-xl p-5 flex justify-between items-center transition-all-500"
          id="navbar"
          phx-hook="NavbarScroll"
        >
          <div><.link class="nav-link font-bold text-2xl" href="/">Curatorian</.link></div>

          <div class="hidden lg:block">
            <div class="flex space-x-6 font-semibold">
              <%= for menu <- @menus do %>
                <.link class="nav-link" navigate={menu.url}>{menu.title}</.link>
              <% end %>
            </div>
          </div>

          <%= if @current_user != nil do %>
            <div class="hidden lg:block">
              <div class="flex items-center space-x-2">
                <.theme_toggle />
                <.link href={"/#{@current_user.username}"}>
                  <%= if @current_user.profile && @current_user.profile.user_image do %>
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
                <.link href="/dashboard" class="btn-primary no-underline text-xs">Dashboard</.link>
                <.link href="/logout" method="delete" class="no-underline btn-cancel text-xs">
                  Log out
                </.link>
              </div>
            </div>
          <% else %>
            <div class="hidden lg:flex lg:items-center lg:space-x-4">
              <.theme_toggle />
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
          class="lg:hidden hidden h-screen bg-white/90 dark:bg-gray-800/90 rounded-xl shadow-md p-6 space-y-4 font-semibold transition-all duration-300"
        >
          <div class="flex justify-between items-center mb-6 pb-4 border-b border-gray-200 dark:border-gray-700">
            <%= if @current_user != nil do %>
              <div class="flex items-center gap-3">
                <.link href={"/#{@current_user.username}"}>
                  <%= if @current_user.profile && @current_user.profile.user_image do %>
                    <img
                      src={@current_user.profile.user_image}
                      class="w-10 h-10 object-cover rounded-full"
                      referrerPolicy="no-referrer"
                      alt={@current_user.username}
                    />
                  <% else %>
                    <img
                      src="/images/default.png"
                      class="w-10 h-10 object-cover rounded-full"
                      alt="Default Avatar"
                    />
                  <% end %>
                </.link>
                <div class="flex flex-col">
                  <p class="font-semibold text-sm dark:text-white">
                    <%= if @current_user.profile && @current_user.profile.fullname do %>
                      {@current_user.profile.fullname}
                    <% else %>
                      {@current_user.username}
                    <% end %>
                  </p>

                  <.link
                    href={"/#{@current_user.username}"}
                    class="text-xs font-normal no-underline text-gray-600 dark:text-gray-400"
                  >
                    @{@current_user.username}
                  </.link>
                </div>
              </div>
            <% else %>
              <div class="flex items-center gap-2"><.theme_toggle /></div>
            <% end %>

            <button
              class="text-4xl font-bold text-gray-500 dark:text-gray-400"
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
                class="block nav-link hover:font-black transition-all duration-500 dark:text-white"
                navigate={menu.url}
              >
                {menu.title}
              </.link>
            <% end %>
          </div>

          <div class="pt-6 mt-auto border-t border-gray-200 dark:border-gray-700">
            <%= if @current_user != nil do %>
              <div class="flex flex-col items-center justify-center gap-4 pt-4">
                <div class="flex gap-3 w-full"><.theme_toggle /></div>

                <div class="flex flex-col gap-3 w-full">
                  <.link href="/dashboard" class="btn-primary no-underline text-sm text-center w-full">
                    Dashboard
                  </.link>
                  <.link
                    href="/logout"
                    method="delete"
                    class="no-underline btn-cancel text-sm text-center w-full"
                  >
                    Log out
                  </.link>
                </div>
              </div>
            <% else %>
              <div class="flex flex-col gap-4 pt-4">
                <.link class="no-underline w-full" href="/login">
                  <button class="btn-primary bg-violet-1 text-violet-6 w-full">Masuk</button>
                </.link>
              </div>
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
