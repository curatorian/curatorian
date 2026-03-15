defmodule CuratorianWeb.Public.ProfileShowLive do
  @moduledoc "Public profile detail page (/u/:username)."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @social_icon_map %{
    "twitter" => "https://twitter.com/",
    "linkedin" => "https://linkedin.com/in/",
    "instagram" => "https://instagram.com/",
    "facebook" => "https://facebook.com/",
    "github" => "https://github.com/",
    "website" => nil
  }

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"username" => username}, _uri, socket) do
    case Public.get_public_profile(username) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Profil tidak ditemukan.")
         |> push_navigate(to: ~p"/kurator")}

      profile ->
        blog_posts = Public.list_user_blog_posts(profile.voile_user_id)

        {:noreply,
         socket
         |> assign(:page_title, profile.display_name)
         |> assign(:profile, profile)
         |> assign(:blog_posts, blog_posts)}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto pb-12 px-4">
        <%!-- Cover photo --%>
        <div class="relative -mx-4 -mt-8 mb-0 h-48 md:h-64 overflow-hidden">
          <%= if @profile.cover_url do %>
            <img src={asset_url(@profile.cover_url)} alt="" class="w-full h-full object-cover" />
          <% else %>
            <div class="w-full h-full bg-gradient-to-br from-violet-400 via-purple-500 to-indigo-600">
            </div>
          <% end %>
          <div class="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent"></div>
        </div>

        <%!-- Profile header --%>
        <div class="relative -mt-16 px-4 pb-4">
          <div class="flex flex-col sm:flex-row sm:items-end gap-4">
            <%!-- Avatar --%>
            <div class="w-28 h-28 rounded-full ring-4 ring-base-100 overflow-hidden bg-violet-200 dark:bg-violet-800 flex items-center justify-center shrink-0">
              <%= if @profile.avatar_url do %>
                <img
                  src={asset_url(@profile.avatar_url)}
                  alt={@profile.display_name}
                  class="w-full h-full object-cover"
                />
              <% else %>
                <span class="text-4xl font-bold text-violet-600 dark:text-violet-300">
                  {String.first(@profile.display_name || "K")}
                </span>
              <% end %>
            </div>

            <%!-- Name & meta --%>
            <div class="pb-1 min-w-0">
              <div class="flex items-center gap-2 flex-wrap">
                <h1 class="text-2xl md:text-3xl font-bold leading-tight">
                  {@profile.display_name}
                </h1>
                <.icon
                  :if={@profile.is_verified}
                  name="hero-check-badge"
                  class="w-6 h-6 text-primary shrink-0"
                />
                <%= if @profile.institution_type do %>
                  <span class="badge badge-outline capitalize text-xs">
                    {@profile.institution_type}
                  </span>
                <% end %>
              </div>
              <p class="text-base-content/50 text-sm mt-0.5">@{@profile.username}</p>
              <p :if={@profile.headline} class="text-base-content/80 mt-1 text-sm md:text-base">
                {@profile.headline}
              </p>
            </div>
          </div>

          <%!-- Stats row --%>
          <div class="flex flex-wrap gap-6 mt-4 text-sm text-base-content/60">
            <span class="flex items-center gap-1">
              <.icon name="hero-users" class="w-4 h-4" />
              <strong class="text-base-content">{@profile.follower_count}</strong> pengikut
            </span>
            <span class="flex items-center gap-1">
              <.icon name="hero-user-plus" class="w-4 h-4" />
              <strong class="text-base-content">{@profile.following_count}</strong> mengikuti
            </span>
            <span :if={@profile.webinar_hosted_count > 0} class="flex items-center gap-1">
              <.icon name="hero-video-camera" class="w-4 h-4" />
              <strong class="text-base-content">{@profile.webinar_hosted_count}</strong> webinar
            </span>
            <span :if={@profile.city} class="flex items-center gap-1">
              <.icon name="hero-map-pin" class="w-4 h-4" />
              {@profile.city}
              <%= if @profile.province do %>
                , {@profile.province}
              <% end %>
            </span>
          </div>
        </div>

        <%!-- Main content grid --%>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-4 px-4">
          <%!-- Left column: bio + details --%>
          <div class="md:col-span-2 space-y-6">
            <%!-- Bio --%>
            <div :if={@profile.bio} class="card bg-base-100 border border-base-300 shadow-sm">
              <div class="card-body">
                <h2 class="card-title text-base">Tentang</h2>
                <p class="text-base-content/80 whitespace-pre-line text-sm leading-relaxed">
                  {@profile.bio}
                </p>
              </div>
            </div>

            <%!-- Education --%>
            <div
              :if={@profile.education != [] and @profile.education != nil}
              class="card bg-base-100 border border-base-300 shadow-sm"
            >
              <div class="card-body">
                <h2 class="card-title text-base flex items-center gap-2">
                  <.icon name="hero-academic-cap" class="w-5 h-5 text-primary" /> Pendidikan
                </h2>
                <div class="space-y-3 mt-1">
                  <%= for edu <- @profile.education do %>
                    <div class="border-l-2 border-primary/30 pl-3">
                      <p class="font-semibold text-sm">{edu["institution"] || edu["school"]}</p>
                      <p class="text-sm text-base-content/70">
                        {edu["degree"]} — {edu["field"]}
                      </p>
                      <p :if={edu["year"]} class="text-xs text-base-content/50">{edu["year"]}</p>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <%!-- Certifications --%>
            <div
              :if={@profile.certifications != [] and @profile.certifications != nil}
              class="card bg-base-100 border border-base-300 shadow-sm"
            >
              <div class="card-body">
                <h2 class="card-title text-base flex items-center gap-2">
                  <.icon name="hero-trophy" class="w-5 h-5 text-primary" /> Sertifikasi
                </h2>
                <div class="space-y-3 mt-1">
                  <%= for cert <- @profile.certifications do %>
                    <div class="flex items-start gap-2">
                      <div class="w-2 h-2 rounded-full bg-primary mt-1.5 shrink-0"></div>
                      <div>
                        <p class="font-semibold text-sm">{cert["name"]}</p>
                        <p :if={cert["issuer"]} class="text-xs text-base-content/60">
                          {cert["issuer"]}
                          <span :if={cert["year"]}> ·    {cert["year"]}</span>
                        </p>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <%!-- Blog posts --%>
            <div :if={@blog_posts != []} class="card bg-base-100 border border-base-300 shadow-sm">
              <div class="card-body">
                <h2 class="card-title text-base flex items-center gap-2">
                  <.icon name="hero-document-text" class="w-5 h-5 text-primary" /> Tulisan
                </h2>
                <div class="space-y-4 mt-1 divide-y divide-base-200">
                  <%= for post <- @blog_posts do %>
                    <.link
                      navigate={~p"/u/#{@profile.username}/blog/#{post.slug}"}
                      class="block group pt-3 first:pt-0"
                    >
                      <div class="flex gap-3">
                        <%= if post.cover_url && post.cover_url != "" do %>
                          <img
                            src={asset_url(post.cover_url)}
                            alt=""
                            class="w-16 h-11 rounded-lg object-cover shrink-0"
                          />
                        <% end %>
                        <div class="flex-1 min-w-0">
                          <p class="font-semibold text-sm leading-snug group-hover:text-primary transition-colors line-clamp-2">
                            {post.title}
                          </p>
                          <p class="text-xs text-base-content/50 mt-0.5">
                            {Calendar.strftime(post.published_at, "%d %b %Y")}
                            <%= if post.comment_count > 0 do %>
                              ·
                              <span class="inline-flex items-center gap-0.5">
                                <.icon
                                  name="hero-chat-bubble-left-ellipsis-micro"
                                  class="w-3 h-3"
                                />
                                {post.comment_count}
                              </span>
                            <% end %>
                          </p>
                        </div>
                      </div>
                    </.link>
                  <% end %>
                </div>
              </div>
            </div>
          </div>

          <%!-- Right column: sidebar --%>
          <div class="space-y-4">
            <%!-- Current position --%>
            <div
              :if={@profile.current_position || @profile.current_institution}
              class="card bg-base-100 border border-base-300 shadow-sm"
            >
              <div class="card-body py-4">
                <h2 class="font-semibold text-sm text-base-content/60 uppercase tracking-wide">
                  Posisi Saat Ini
                </h2>
                <p :if={@profile.current_position} class="font-semibold text-sm mt-1">
                  {@profile.current_position}
                </p>
                <p :if={@profile.current_institution} class="text-sm text-base-content/70">
                  <.icon name="hero-building-office-2-micro" class="w-3 h-3 inline mr-1" />
                  {@profile.current_institution}
                </p>
                <p :if={@profile.years_experience} class="text-xs text-base-content/50">
                  {@profile.years_experience} tahun pengalaman
                </p>
              </div>
            </div>

            <%!-- Social links --%>
            <div
              :if={@profile.social_links != %{} and @profile.social_links != nil}
              class="card bg-base-100 border border-base-300 shadow-sm"
            >
              <div class="card-body py-4">
                <h2 class="font-semibold text-sm text-base-content/60 uppercase tracking-wide">
                  Tautan
                </h2>
                <div class="space-y-2 mt-1">
                  <%= for {platform, url} <- @profile.social_links, url != nil and url != "" do %>
                    <a
                      href={normalize_social_url(platform, url)}
                      target="_blank"
                      rel="noopener noreferrer"
                      class="flex items-center gap-2 text-sm text-primary hover:underline"
                    >
                      <.icon name="hero-link" class="w-3.5 h-3.5 shrink-0" />
                      <span class="truncate capitalize">{platform}</span>
                    </a>
                  <% end %>
                </div>
              </div>
            </div>

            <%!-- Back link --%>
            <.link
              navigate={~p"/kurator"}
              class="btn btn-sm btn-ghost w-full text-base-content/60 hover:text-base-content"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> Kembali ke daftar kurator
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp normalize_social_url(platform, url) do
    base = Map.get(@social_icon_map, platform)

    cond do
      String.starts_with?(url, "http") -> url
      base != nil -> base <> url
      true -> "https://#{url}"
    end
  end
end
