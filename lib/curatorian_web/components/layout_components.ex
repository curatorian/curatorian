defmodule CuratorianWeb.LayoutComponents do
  use Phoenix.Component
  use Phoenix.LiveComponent
  use Gettext, backend: CuratorianWeb.Gettext

  import CuratorianWeb.CoreComponents

  # alias Phoenix.LiveView.JS

  attr :current_user, :map

  def navigation_header(assigns) do
    ~H"""
    <header class="fixed w-full p-0 md:p-5">
      <nav class="max-w-7xl bg-violet-100 mx-auto list-none p-5">
        <div class="flex items-center justify-between">
          <div>
            <h3>Curatorian</h3>
          </div>
          
          <div>
            <ul class="flex gap-5">
              <li>Home</li>
              
              <li>Profile</li>
            </ul>
          </div>
          
          <div class="flex gap-2">
            <%= if @current_user do %>
              <li class="text-[0.8125rem] leading-6 text-zinc-900">
                Halo, {@current_user.username}!
              </li>
              
              <li>
                <.link
                  href="/users/settings"
                  class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
                >
                  Settings
                </.link>
              </li>
              
              <li>
                <.link
                  href="/users/log_out"
                  method="delete"
                  class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
                >
                  Log out
                </.link>
              </li>
            <% else %>
              <div class="flex gap-2">
                <.button class="btn">
                  Masuk
                </.button>
                
                <.button class="secondary-btn">
                  Daftar
                </.button>
              </div>
            <% end %>
          </div>
        </div>
      </nav>
    </header>
    """
  end
end
