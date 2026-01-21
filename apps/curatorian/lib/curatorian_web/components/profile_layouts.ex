defmodule CuratorianWeb.ProfileLayouts do
  use CuratorianWeb, :html

  attr :user, :map, required: true
  attr :current_scope, :map, required: true
  attr :active_tab, :string, required: true
  slot :inner_block, required: true

  def profile_layout(assigns) do
    ~H"""
    <div class="container mx-auto p-4 flex flex-col xl:flex-row gap-10">
      <div class="w-full xl:max-w-sm">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h3 class="dark:text-white">{@user.username}'s Profile</h3>
            <.button navigate={~p"/kurator"}>Kembali</.button>
          </div>
        </div>

        <div>
          <img
            src={~p"/images/lib.webp"}
            alt="Background"
            class="w-full h-64 object-cover rounded-t-lg"
          />
          <div class="bg-white dark:bg-gray-700 shadow-md rounded-lg p-6">
            <div class="flex justify-between">
              <%= if @user.profile && @user.profile.user_image do %>
                <img
                  src={@user.profile.user_image}
                  alt="Profile Picture"
                  class="main-profile-pic"
                  referrerPolicy="no-referrer"
                />
              <% else %>
                <img
                  src={~p"/images/default.png"}
                  alt="Default Profile Picture"
                  class="main-profile-pic"
                  referrerPolicy="no-referrer"
                />
              <% end %>

              <%= if @current_scope.user && @current_scope.user.id == @user.id do %>
                <.link
                  navigate={~p"/users/settings"}
                  class="btn-primary w-full max-w-24 text-xs no-underline"
                >
                  Edit Profile
                </.link>
              <% end %>
            </div>

            <div class="flex items-center space-x-4 my-5">
              <div>
                <div class="flex items-center gap-2">
                  <h2 class="text-xl font-semibold dark:text-white">
                    {if @user.profile == nil, do: @user.username, else: @user.profile.fullname}
                  </h2>

                  <%= if @user.is_verified do %>
                    <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                      <.icon name="hero-check-circle" class="w-3 h-3 mr-1" /> Verified
                    </span>
                  <% end %>
                </div>

                <p class="text-gray-500 dark:text-gray-400">@{@user.username}</p>
              </div>
            </div>

            <div class="my-4">
              <h3 class="text-lg font-medium dark:text-white">About</h3>

              <%= if @user.profile && @user.profile.bio do %>
                <p class="text-gray-500 dark:text-gray-400 mt-2">{@user.profile.bio}</p>
              <% else %>
                <p class="text-gray-500 dark:text-gray-400 mt-2">
                  Curatorian baru! Silahkan sapa saya.
                </p>
              <% end %>
            </div>

            <div class="my-4">
              <h3 class="text-lg font-medium dark:text-white">Email</h3>

              <p class="text-gray-500 dark:text-gray-400 mt-2">{@user.email}</p>
            </div>
          </div>
        </div>
      </div>

      <div class="min-h-screen w-full">
        <div class="flex justify-start mb-6">
          <div class="flex space-x-4 border-b-2 border-gray-200 dark:border-gray-600">
            <.link navigate={~p"/#{@user.username}/blogs"}>
              <button class={"px-4 py-2 focus:outline-none hover:text-violet-500 dark:hover:text-violet-300 cursor-pointer #{if @active_tab == "blogs", do: "border-b-2 border-violet-500 text-violet-500 dark:text-violet-300", else: "text-gray-500 dark:text-gray-400"}"}>
                Blogs
              </button>
            </.link>
            <.link navigate={~p"/#{@user.username}/posts"}>
              <button class={"px-4 py-2 focus:outline-none hover:text-violet-500 dark:hover:text-violet-300 cursor-pointer #{if @active_tab == "posts", do: "border-b-2 border-violet-500 text-violet-500 dark:text-violet-300", else: "text-gray-500 dark:text-gray-400"}"}>
                Posts
              </button>
            </.link>
            <.link navigate={~p"/#{@user.username}/works"}>
              <button class={"px-4 py-2 focus:outline-none hover:text-violet-500 dark:hover:text-violet-300 cursor-pointer #{if @active_tab == "works", do: "border-b-2 border-violet-500 text-violet-500 dark:text-violet-300", else: "text-gray-500 dark:text-gray-400"}"}>
                Works
              </button>
            </.link>
          </div>
        </div>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
