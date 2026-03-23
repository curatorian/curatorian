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

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"username" => username}, _uri, socket) do
    case Public.get_public_profile(username) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Profil tidak ditemukan.")
         |> push_navigate(to: ~p"/kurator")}

      profile ->
        blog_posts = Public.list_user_blog_posts(profile.voile_user_id)

        current_user_id =
          if socket.assigns.current_scope && socket.assigns.current_scope.user,
            do: socket.assigns.current_scope.user.id,
            else: nil

        is_following =
          if current_user_id && profile.voile_user_id do
            Public.following?(current_user_id, profile.voile_user_id)
          else
            false
          end

        {:noreply,
         socket
         |> assign(:page_title, profile.display_name)
         |> assign(:profile, profile)
         |> assign(:blog_posts, blog_posts)
         |> assign(:is_following, is_following)}
    end
  end

  @impl true
  def handle_event("follow", params, socket) do
    target_id = params["user_id"] || params["user-id"]
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user

    if current_user && target_id do
      case Public.follow_user(current_user.id, target_id) do
        {:ok, _follow} ->
          {:noreply, assign(socket, :is_following, true)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not follow user.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please log in to follow users.")}
    end
  end

  @impl true
  def handle_event("unfollow", params, socket) do
    target_id = params["user_id"] || params["user-id"]
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user

    if current_user && target_id do
      case Public.unfollow_user(current_user.id, target_id) do
        :ok ->
          {:noreply, assign(socket, :is_following, false)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not unfollow user.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please log in to unfollow users.")}
    end
  end

  @impl true
  def handle_event("message", params, socket) do
    target_id = params["user_id"] || params["user-id"]
    current_user = socket.assigns.current_scope && socket.assigns.current_scope.user

    if current_user && target_id do
      case Public.get_or_create_thread(current_user.id, target_id) do
        {:ok, thread} ->
          atrium_url =
            System.get_env("ATRIUM_URL") ||
              Application.get_env(:curatorian, :atrium_url, "http://localhost:4001")

          {:noreply,
           redirect(socket,
             external: "#{atrium_url}/community/messages/#{thread.id}"
           )}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not open conversation.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please log in to send messages.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <%= if @profile.is_public do %>
        <%!-- ============================================================
             HERO COVER — bleeds through the section's pt-48 px-5 padding
             ============================================================ --%>
        <div class="-mt-48 -mx-5 relative h-72 md:h-[26rem] overflow-hidden">
          <%= if @profile.cover_url do %>
            <img
              src={asset_url(@profile.cover_url)}
              alt=""
              class="absolute inset-0 w-full h-full object-cover"
            />
          <% else %>
            <div class="absolute inset-0 bg-gradient-to-br from-primary via-accent to-accent/70">
            </div>
          <% end %>
          <%!-- cinematic vignette --%>
          <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-black/35"></div>
          <%!-- verified pill — top right --%>
          <div :if={@profile.is_verified} class="absolute top-20 right-6 z-10">
            <span class="inline-flex items-center gap-1.5 bg-white/15 backdrop-blur-md text-white text-xs font-semibold px-3 py-1.5 rounded-full border border-white/20 shadow">
              <.icon name="hero-check-badge" class="w-3.5 h-3.5" /> Terverifikasi
            </span>
          </div>
          <%!-- avatar + identity — pinned to bottom of cover --%>
          <div class="absolute bottom-0 left-0 right-0 px-6 md:px-10 pb-8 flex items-end gap-5">
            <div class="w-24 h-24 md:w-32 md:h-32 rounded-3xl ring-4 ring-white/25 shadow-2xl overflow-hidden bg-gradient-to-br from-primary to-accent flex items-center justify-center shrink-0">
              <%= if @profile.avatar_url do %>
                <img
                  src={asset_url(@profile.avatar_url)}
                  alt={@profile.display_name}
                  class="w-full h-full object-cover"
                />
              <% else %>
                <span class="text-4xl md:text-5xl font-bold text-white select-none">
                  {String.first(@profile.display_name || "K")}
                </span>
              <% end %>
            </div>
            <div class="pb-1 flex-1 min-w-0">
              <div class="flex flex-wrap items-center gap-2.5">
                <h1 class="text-2xl md:text-4xl font-bold text-white leading-tight drop-shadow-lg">
                  {@profile.display_name}
                </h1>
                <span
                  :if={@profile.institution_type}
                  class="badge badge-sm bg-white/20 text-white border-white/30 backdrop-blur-sm capitalize"
                >
                  {@profile.institution_type}
                </span>
              </div>
              <p class="text-white/55 text-sm font-mono mt-1">@{@profile.username}</p>

              <%= if @current_scope && @current_scope.user && @current_scope.user.id != @profile.voile_user_id do %>
                <div class="mt-2 flex items-center gap-2">
                  <button
                    phx-click="message"
                    phx-value-user-id={@profile.voile_user_id}
                    class="btn btn-sm bg-success text-white border-success hover:bg-success/90"
                    type="button"
                  >
                    <.icon name="hero-chat-bubble-left-ellipsis" class="size-4 mr-1" /> Pesan
                  </button>

                  <%= if @is_following do %>
                    <button
                      phx-click="unfollow"
                      phx-value-user-id={@profile.voile_user_id}
                      class="btn btn-sm text-white border-red-500 bg-red-500 hover:bg-red-500/70"
                      type="button"
                    >
                      Unfollow
                    </button>
                  <% else %>
                    <button
                      phx-click="follow"
                      phx-value-user-id={@profile.voile_user_id}
                      class="btn btn-sm border-white text-white bg-primary hover:bg-primary/70"
                      type="button"
                    >
                      Follow
                    </button>
                  <% end %>
                </div>
              <% end %>

              <p
                :if={@profile.headline}
                class="text-white/80 text-sm md:text-base mt-2 leading-snug max-w-2xl"
              >
                {@profile.headline}
              </p>
            </div>
          </div>
        </div>

        <%!-- ============================================================
           STATS BAR — full-bleed white strip beneath cover
           ============================================================ --%>
        <div class="-mx-5 bg-base-100 border-b border-base-300 shadow">
          <div class="max-w-5xl mx-auto px-6 md:px-10 py-4 flex flex-wrap items-center gap-x-8 gap-y-3">
            <div class="flex flex-col items-center">
              <span class="text-2xl font-bold text-base-content tabular-nums">
                {@profile.follower_count}
              </span>
              <span class="text-[10px] uppercase tracking-widest text-base-content/45 mt-0.5">
                Pengkaji
              </span>
            </div>
            <div class="w-px h-8 bg-base-300 hidden sm:block"></div>
            <div class="flex flex-col items-center">
              <span class="text-2xl font-bold text-base-content tabular-nums">
                {@profile.following_count}
              </span>
              <span class="text-[10px] uppercase tracking-widest text-base-content/45 mt-0.5">
                Mengkaji
              </span>
            </div>
            <div
              :if={@profile.event_hosted_count > 0}
              class="flex flex-col items-center"
            >
              <div class="w-px h-8 bg-base-300 hidden sm:block -mb-8 mr-8"></div>
              <span class="text-2xl font-bold text-base-content tabular-nums">
                {@profile.event_hosted_count}
              </span>
              <span class="text-[10px] uppercase tracking-widest text-base-content/45 mt-0.5">
                Webinar
              </span>
            </div>
            <div
              :if={@profile.city}
              class="ml-auto flex items-center gap-1.5 text-sm text-base-content/55"
            >
              <.icon name="hero-map-pin" class="w-4 h-4 text-primary" />
              {if @profile.province,
                do: "#{@profile.city}, #{@profile.province}",
                else: @profile.city}
            </div>
          </div>
        </div>

        <%!-- DM preference summary from user profile --%>
        <div class="-mx-5 bg-base-100 border-b border-base-300">
          <div class="max-w-5xl mx-auto px-6 md:px-10 py-3 text-sm text-base-content/75">
            <p class="font-semibold text-base-content mb-1">Pengaturan pesan langsung</p>
            <p>
              <%= if @profile.allow_dms do %>
                <span class="text-success">Pesan langsung diizinkan</span>
              <% else %>
                <span class="text-error">Pesan langsung dinonaktifkan</span>
              <% end %>
            </p>
            <p>
              <%= cond do %>
                <% !@profile.allow_dms -> %>
                  <span class="text-base-content/60">Pesan langsung tidak tersedia.</span>
                <% @profile.dm_from_followers_only -> %>
                  <span class="text-base-content/60">
                    Hanya pengikut timbal balik yang dapat mengirim pesan.
                  </span>
                <% true -> %>
                  <span class="text-base-content/60">Siapa pun dapat mengirim pesan langsung.</span>
              <% end %>
            </p>
          </div>
        </div>

        <%!-- ============================================================
           MAIN CONTENT
           ============================================================ --%>
        <div class="max-w-5xl mx-auto pt-8 pb-20 px-2 sm:px-0">
          <%!-- Breadcrumb --%>
          <div class="mb-7">
            <.link
              navigate={~p"/kurator"}
              class="inline-flex items-center gap-1.5 text-base-content/45 hover:text-base-content text-sm transition-colors"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> Kembali ke daftar kurator
            </.link>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
            <%!-- --------------------------------------------------------
               MAIN COLUMN (2/3)
               -------------------------------------------------------- --%>
            <div class="md:col-span-2 space-y-4">
              <%!-- Bio --%>
              <section
                :if={@profile.bio}
                class="bg-base-100 rounded-2xl border border-base-300 shadow-sm p-6 hover:shadow-md transition-shadow duration-200"
              >
                <p class="text-[10px] font-bold uppercase tracking-widest text-base-content/35 mb-3">
                  Tentang
                </p>
                <p class="text-base-content/80 text-sm leading-relaxed whitespace-pre-line">
                  {@profile.bio}
                </p>
              </section>

              <%!-- Education --%>
              <section
                :if={@profile.education != [] and @profile.education != nil}
                class="bg-base-100 rounded-2xl border border-base-300 shadow-sm p-6 hover:shadow-md transition-shadow duration-200"
              >
                <p class="text-[10px] font-bold uppercase tracking-widest text-base-content/35 mb-5 flex items-center gap-1.5">
                  <.icon name="hero-academic-cap" class="w-3.5 h-3.5 text-primary" /> Pendidikan
                </p>
                <div>
                  <%= for {edu, idx} <- Enum.with_index(@profile.education) do %>
                    <div class="flex gap-4">
                      <div class="flex flex-col items-center">
                        <div class="w-8 h-8 rounded-xl bg-primary/10 flex items-center justify-center shrink-0 text-xs font-bold text-primary">
                          {idx + 1}
                        </div>
                        <div
                          :if={idx < length(@profile.education) - 1}
                          class="w-px flex-1 bg-base-300 my-2 min-h-4"
                        >
                        </div>
                      </div>
                      <div class="pb-5 flex-1 min-w-0">
                        <p class="font-semibold text-sm">{edu["institution"] || edu["school"]}</p>
                        <p class="text-sm text-base-content/60 mt-0.5">
                          {edu["degree"]}<span :if={edu["field"]}> · {edu["field"]}</span>
                        </p>
                        <p :if={edu["year"]} class="text-xs text-base-content/40 font-mono mt-0.5">
                          {edu["year"]}
                        </p>
                      </div>
                    </div>
                  <% end %>
                </div>
              </section>

              <%!-- Certifications --%>
              <section
                :if={@profile.certifications != [] and @profile.certifications != nil}
                class="bg-base-100 rounded-2xl border border-base-300 shadow-sm p-6 hover:shadow-md transition-shadow duration-200"
              >
                <p class="text-[10px] font-bold uppercase tracking-widest text-base-content/35 mb-4 flex items-center gap-1.5">
                  <.icon name="hero-trophy" class="w-3.5 h-3.5 text-primary" /> Sertifikasi
                </p>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <%= for cert <- @profile.certifications do %>
                    <div class="flex items-start gap-3 bg-base-200/50 hover:bg-base-200 rounded-xl p-3.5 transition-colors">
                      <span class="flex items-center justify-center w-9 h-9 rounded-xl bg-primary/15 text-primary shrink-0">
                        <.icon name="hero-check-badge" class="w-5 h-5" />
                      </span>
                      <div class="min-w-0">
                        <p class="font-semibold text-sm leading-snug">{cert["name"]}</p>
                        <p :if={cert["issuer"]} class="text-xs text-base-content/50 mt-0.5">
                          {cert["issuer"]}
                          <span :if={cert["year"]} class="font-mono">
                            · {cert["year"]}
                          </span>
                        </p>
                      </div>
                    </div>
                  <% end %>
                </div>
              </section>

              <%!-- Blog posts --%>
              <section
                :if={@blog_posts != []}
                class="bg-base-100 rounded-2xl border border-base-300 shadow-sm p-6 hover:shadow-md transition-shadow duration-200"
              >
                <p class="text-[10px] font-bold uppercase tracking-widest text-base-content/35 mb-4 flex items-center gap-1.5">
                  <.icon name="hero-document-text" class="w-3.5 h-3.5 text-primary" /> Tulisan
                </p>
                <div class="space-y-1">
                  <%= for post <- @blog_posts do %>
                    <.link
                      navigate={~p"/u/#{@profile.username}/blog/#{post.slug}"}
                      class="flex items-center gap-4 -mx-3 px-3 py-3 rounded-xl hover:bg-base-200/70 transition-colors group"
                    >
                      <%= if post.cover_url && post.cover_url != "" do %>
                        <img
                          src={asset_url(post.cover_url)}
                          alt=""
                          class="w-16 h-11 rounded-lg object-cover shrink-0"
                        />
                      <% else %>
                        <div class="w-16 h-11 rounded-lg bg-gradient-to-br from-primary/20 to-accent/30 shrink-0">
                        </div>
                      <% end %>
                      <div class="flex-1 min-w-0">
                        <p class="font-medium text-sm leading-snug group-hover:text-primary transition-colors line-clamp-2">
                          {post.title}
                        </p>
                        <p class="text-xs text-base-content/40 mt-1 flex items-center gap-1.5">
                          {Calendar.strftime(post.published_at, "%d %b %Y")}
                          <span :if={post.comment_count > 0} class="flex items-center gap-1">
                            · <.icon name="hero-chat-bubble-left-ellipsis-micro" class="w-3 h-3" />
                            {post.comment_count}
                          </span>
                        </p>
                      </div>
                      <.icon
                        name="hero-chevron-right"
                        class="w-4 h-4 text-base-content/20 group-hover:text-primary transition-colors shrink-0"
                      />
                    </.link>
                  <% end %>
                </div>
              </section>

              <%!-- Empty state --%>
              <section
                :if={
                  !@profile.bio and
                    (@profile.education == [] or @profile.education == nil) and
                    (@profile.certifications == [] or @profile.certifications == nil) and
                    @blog_posts == []
                }
                class="bg-base-100 rounded-2xl border border-base-300 border-dashed shadow-sm p-16 flex flex-col items-center justify-center text-center"
              >
                <div class="w-16 h-16 rounded-3xl bg-base-200 flex items-center justify-center mb-4">
                  <.icon name="hero-user" class="w-8 h-8 text-base-content/20" />
                </div>
                <p class="font-semibold text-base-content/40 text-sm">Profil belum dilengkapi</p>
                <p class="text-base-content/30 text-xs mt-1">Informasi tambahan belum tersedia</p>
              </section>
            </div>

            <%!-- --------------------------------------------------------
               SIDEBAR (1/3)
               -------------------------------------------------------- --%>
            <div class="space-y-4">
              <%!-- Current position --%>
              <section
                :if={@profile.current_position || @profile.current_institution}
                class="bg-base-100 rounded-2xl border border-base-300 shadow-sm p-5"
              >
                <p class="text-[10px] font-bold uppercase tracking-widest text-base-content/35 mb-4">
                  Posisi Saat Ini
                </p>
                <div class="flex items-start gap-3">
                  <div class="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
                    <.icon name="hero-briefcase" class="w-5 h-5 text-primary" />
                  </div>
                  <div class="min-w-0">
                    <p :if={@profile.current_position} class="font-semibold text-sm leading-snug">
                      {@profile.current_position}
                    </p>
                    <p :if={@profile.current_institution} class="text-xs text-base-content/55 mt-0.5">
                      {@profile.current_institution}
                    </p>
                    <p
                      :if={@profile.years_experience}
                      class="text-xs text-base-content/40 font-mono mt-1.5"
                    >
                      {@profile.years_experience} tahun pengalaman
                    </p>
                  </div>
                </div>
              </section>

              <%!-- Social links --%>
              <section
                :if={@profile.social_links != %{} and @profile.social_links != nil}
                class="bg-base-100 rounded-2xl border border-base-300 shadow-sm p-5"
              >
                <p class="text-[10px] font-bold uppercase tracking-widest text-base-content/35 mb-3">
                  Tautan
                </p>
                <div class="space-y-0.5">
                  <%= for {platform, url} <- @profile.social_links, url != nil and url != "" do %>
                    <a
                      href={normalize_social_url(platform, url)}
                      target="_blank"
                      rel="noopener noreferrer"
                      class="flex items-center gap-2.5 -mx-2 px-2 py-2 rounded-xl hover:bg-base-200 text-sm text-base-content/65 hover:text-primary transition-all group"
                    >
                      <.icon
                        name="hero-arrow-top-right-on-square"
                        class="w-3.5 h-3.5 text-base-content/25 group-hover:text-primary transition-colors shrink-0"
                      />
                      <span class="capitalize font-medium">{platform}</span>
                    </a>
                  <% end %>
                </div>
              </section>

              <%!-- Webinar attended big number --%>
              <section
                :if={@profile.event_attended_count > 0}
                class="bg-primary/8 border border-primary/20 rounded-2xl p-5"
              >
                <p class="text-[10px] font-bold uppercase tracking-widest text-primary/60 mb-1">
                  Webinar Diikuti
                </p>
                <p class="text-5xl font-bold text-primary tabular-nums leading-none mt-2">
                  {@profile.event_attended_count}
                </p>
              </section>
            </div>
          </div>
        </div>
      <% else %>
        <div class="max-w-5xl mx-auto pt-8 pb-20 px-2 sm:px-0 text-center">
          <div class="bg-base-100 rounded-2xl border border-base-300 shadow-sm p-10">
            <h1 class="text-3xl font-bold text-base-content mb-2">{@profile.display_name}</h1>
            <p class="text-base-content/60 mb-4">@{@profile.username}</p>
            <p class="text-base-content/50">
              Profil ini tidak dipublikasikan oleh pemiliknya. Hanya nama dan pengguna yang terlihat.
            </p>
          </div>
        </div>
      <% end %>
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
