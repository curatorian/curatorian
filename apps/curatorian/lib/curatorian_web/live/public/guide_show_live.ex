defmodule CuratorianWeb.Public.GuideShowLive do
  @moduledoc "Public single guide view with sticky TOC and reading progress."

  use CuratorianWeb, :live_view

  alias Curatorian.Public

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    guide = Public.get_guide_by_slug!(slug)

    # Increment view count asynchronously
    Task.start(fn -> Public.increment_guide_view(guide.id) end)

    {content_html, toc} = prepare_content(guide.content_html)

    series_guides =
      if guide.series_id,
        do: Public.list_published_series_guides(guide.series_id),
        else: []

    og_title = guide.title
    og_description = guide.description || preview_description(guide.content_html)
    og_image = guide.cover_url
    og_url = "/guides/#{slug}"

    {:ok,
     socket
     |> assign(:page_title, guide.title)
     |> assign(:guide, guide)
     |> assign(:content_html, content_html)
     |> assign(:toc, toc)
     |> assign(:series_guides, series_guides)
     |> assign(:og_title, og_title)
     |> assign(:og_description, og_description)
     |> assign(:og_image, og_image)
     |> assign(:og_url, og_url)
     |> assign(:og_type, "article")
     |> assign(:twitter_card, if(og_image, do: "summary_large_image", else: "summary"))}
  end

  defp preview_description(html) do
    html
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.slice(0, 200)
  end

  # Process HTML content: inject IDs into headings without them and generate TOC.
  defp prepare_content(nil), do: {"", []}
  defp prepare_content(""), do: {"", []}

  defp prepare_content(html) do
    heading_regex = ~r/<h([2-4])([^>]*)>(.*?)<\/h\1>/is

    toc =
      heading_regex
      |> Regex.scan(html)
      |> Enum.map(fn
        [_full, level, attrs, inner] ->
          text = inner |> String.replace(~r/<[^>]+>/, "") |> String.trim()
          id_match = Regex.run(~r/\bid="([^"]*)"/,  attrs, capture: :all_but_first)
          id = if id_match, do: hd(id_match), else: heading_id(text)
          %{level: String.to_integer(level), id: id, text: text}

        _ ->
          nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&(&1.text == ""))

    html_with_ids =
      Regex.replace(heading_regex, html, fn _full, level, attrs, inner ->
        if String.match?(attrs, ~r/\bid="/) do
          "<h#{level}#{attrs}>#{inner}</h#{level}>"
        else
          text = inner |> String.replace(~r/<[^>]+>/, "") |> String.trim()
          id = heading_id(text)
          "<h#{level} id=\"#{id}\"#{attrs}>#{inner}</h#{level}>"
        end
      end)

    {html_with_ids, toc}
  end

  defp heading_id(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^\p{L}\p{N}\s-]/u, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end

  defp difficulty_label("beginner"), do: "Beginner"
  defp difficulty_label("intermediate"), do: "Intermediate"
  defp difficulty_label("advanced"), do: "Advanced"
  defp difficulty_label(_), do: nil

  defp category_label("getting_started"), do: "Getting Started"
  defp category_label("features"), do: "Features"
  defp category_label("integration"), do: "Integration"
  defp category_label("api"), do: "API"
  defp category_label("faq"), do: "FAQ"
  defp category_label(c) when is_binary(c), do: c |> String.replace("_", " ") |> String.capitalize()
  defp category_label(_), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <%!-- Reading progress bar --%>
      <div
        id="reading-progress-container"
        phx-hook=".ReadingProgress"
        phx-update="ignore"
        class="fixed top-0 left-0 right-0 z-50 h-1 bg-base-200"
      >
        <div id="reading-progress-bar" class="h-full bg-primary transition-all duration-100 w-0"></div>
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".ReadingProgress">
        export default {
          mounted() {
            const bar = document.getElementById("reading-progress-bar");
            const update = () => {
              const scrollable = document.documentElement.scrollHeight - window.innerHeight;
              const progress = scrollable > 0 ? (window.scrollY / scrollable) * 100 : 0;
              bar.style.width = `${Math.min(100, progress)}%`;
            };
            window.addEventListener("scroll", update, { passive: true });
            this._cleanup = () => window.removeEventListener("scroll", update);
          },
          destroyed() { this._cleanup && this._cleanup(); },
        };
      </script>

      <div id="top" class="max-w-6xl mx-auto px-4 py-8">
        <div class="flex flex-col lg:flex-row gap-8">
          <%!-- Main content --%>
          <article class="flex-1 min-w-0">
            <%!-- Breadcrumb --%>
            <nav class="text-sm text-base-content/50 mb-6 flex items-center gap-2">
              <.link navigate={~p"/guides"} class="hover:text-base-content transition-colors">
                Panduan
              </.link>
              <.icon name="hero-chevron-right" class="w-3.5 h-3.5" />
              <span class="text-base-content/70 truncate">{@guide.title}</span>
            </nav>

            <%!-- Cover --%>
            <%= if @guide.cover_url do %>
              <img
                src={@guide.cover_url}
                alt={@guide.title}
                class="w-full h-52 md:h-72 object-cover rounded-2xl mb-6"
              />
            <% end %>

            <%!-- Header --%>
            <header class="mb-8">
              <div class="flex flex-wrap gap-2 mb-3">
                <%= if @guide.category do %>
                  <span class="badge badge-outline capitalize">
                    {category_label(@guide.category)}
                  </span>
                <% end %>
                <%= if @guide.difficulty && difficulty_label(@guide.difficulty) do %>
                  <span class={[
                    "badge",
                    @guide.difficulty == "beginner" && "bg-success/15 text-success",
                    @guide.difficulty == "intermediate" && "bg-warning/15 text-warning-content",
                    @guide.difficulty == "advanced" && "bg-error/15 text-error"
                  ]}>
                    {difficulty_label(@guide.difficulty)}
                  </span>
                <% end %>
              </div>

              <h1 class="text-3xl md:text-4xl font-bold leading-tight">{@guide.title}</h1>

              <%= if @guide.description do %>
                <p class="mt-3 text-lg text-base-content/70 leading-relaxed">{@guide.description}</p>
              <% end %>

              <div class="flex flex-wrap items-center gap-4 mt-4 text-sm text-base-content/50">
                <%= if @guide.estimated_read_minutes do %>
                  <span class="flex items-center gap-1.5">
                    <.icon name="hero-clock" class="w-4 h-4" />
                    {@guide.estimated_read_minutes} menit baca
                  </span>
                <% end %>
                <span class="flex items-center gap-1.5">
                  <.icon name="hero-eye" class="w-4 h-4" />
                  {@guide.view_count} penayangan
                </span>
                <%= if @guide.published_at do %>
                  <span>
                    {Calendar.strftime(@guide.published_at, "%d %b %Y")}
                  </span>
                <% end %>
              </div>

              <%= if @guide.tags && @guide.tags != [] do %>
                <div class="flex flex-wrap gap-1.5 mt-3">
                  <.link
                    :for={tag <- @guide.tags}
                    navigate={~p"/guides?tag=#{tag}"}
                    class="badge badge-sm badge-ghost hover:badge-primary transition-colors"
                  >
                    {tag}
                  </.link>
                </div>
              <% end %>
            </header>

            <%!-- Series navigation (top) --%>
            <%= if @series_guides != [] do %>
              <div class="mb-6 p-4 rounded-xl border border-primary/20 bg-primary/5">
                <p class="text-xs font-semibold uppercase tracking-wider text-primary/70 mb-2">
                  {@guide.series && @guide.series.title}
                </p>
                <div class="flex flex-col gap-1">
                  <%= for part <- @series_guides do %>
                    <% is_current = part.id == @guide.id %>
                    <%= if is_current do %>
                      <span class="flex items-center gap-2 text-sm font-semibold text-primary">
                        <span class="w-5 h-5 shrink-0 rounded-full bg-primary text-primary-content flex items-center justify-center text-xs text-center leading-5">
                          {part.series_position}
                        </span>
                        {part.title}
                      </span>
                    <% else %>
                      <.link
                        navigate={~p"/guides/#{part.slug}"}
                        class="flex items-center gap-2 text-sm text-base-content/60 hover:text-primary transition-colors"
                      >
                        <span class="w-5 h-5 shrink-0 rounded-full border border-base-300 text-xs text-center leading-5">
                          {part.series_position}
                        </span>
                        {part.title}
                      </.link>
                    <% end %>
                  <% end %>
                </div>
              </div>
            <% end %>

            <%!-- Guide content --%>
            <div class="guide-content prose prose-lg max-w-none">
              {raw(@content_html)}
            </div>

            <%!-- Last updated --%>
            <%= if @guide.updated_at && @guide.updated_at != @guide.inserted_at do %>
              <p class="mt-6 text-xs text-base-content/40 flex items-center gap-1.5">
                <.icon name="hero-pencil-square" class="w-3.5 h-3.5" />
                Terakhir diperbarui {Calendar.strftime(@guide.updated_at, "%d %b %Y")}
              </p>
            <% end %>

            <%!-- Series prev/next navigation --%>
            <%= if @series_guides != [] do %>
              <%
                current_idx = Enum.find_index(@series_guides, &(&1.id == @guide.id))
                prev_part = current_idx && current_idx > 0 && Enum.at(@series_guides, current_idx - 1)
                next_part = current_idx && Enum.at(@series_guides, current_idx + 1)
              %>
              <div class="mt-10 pt-8 border-t border-base-200 flex items-center justify-between gap-4">
                <%= if prev_part do %>
                  <.link
                    navigate={~p"/guides/#{prev_part.slug}"}
                    class="flex-1 flex flex-col gap-1 p-4 rounded-xl border border-base-200 hover:border-primary/40 hover:bg-base-50 transition-colors group"
                  >
                    <span class="text-xs text-base-content/40 group-hover:text-primary/70 transition-colors">
                      ← Part {prev_part.series_position}
                    </span>
                    <span class="text-sm font-medium line-clamp-2">{prev_part.title}</span>
                  </.link>
                <% else %>
                  <div class="flex-1" />
                <% end %>

                <%= if next_part do %>
                  <.link
                    navigate={~p"/guides/#{next_part.slug}"}
                    class="flex-1 flex flex-col gap-1 p-4 rounded-xl border border-base-200 hover:border-primary/40 hover:bg-base-50 transition-colors group text-right"
                  >
                    <span class="text-xs text-base-content/40 group-hover:text-primary/70 transition-colors">
                      Part {next_part.series_position} →
                    </span>
                    <span class="text-sm font-medium line-clamp-2">{next_part.title}</span>
                  </.link>
                <% else %>
                  <div class="flex-1" />
                <% end %>
              </div>
            <% end %>

            <%!-- Back to guides --%>
            <div class="mt-12 pt-8 border-t border-base-200 flex items-center justify-between">
              <.link navigate={~p"/guides"} class="btn btn-ghost btn-sm gap-2">
                <.icon name="hero-arrow-left" class="w-4 h-4" />
                Kembali ke Panduan
              </.link>
              <a href="#top" class="btn btn-ghost btn-sm gap-2">
                <.icon name="hero-arrow-up" class="w-4 h-4" />
                Kembali ke Atas
              </a>
            </div>
          </article>

          <%!-- Sticky TOC sidebar --%>
          <%= if @toc != [] do %>
            <aside class="hidden lg:block lg:w-56 shrink-0">
              <div class="sticky top-32">
                <h3 class="text-xs font-semibold uppercase tracking-wider text-base-content/50 mb-3">
                  Daftar Isi
                </h3>
                <nav class="flex flex-col gap-0.5">
                  <a
                    :for={item <- @toc}
                    href={"##{item.id}"}
                    class={[
                      "text-sm hover:text-primary transition-colors py-0.5 rounded",
                      item.level == 2 && "pl-0 text-base-content/70 font-medium",
                      item.level == 3 && "pl-3 text-base-content/60",
                      item.level == 4 && "pl-6 text-base-content/50 text-xs"
                    ]}
                  >
                    {item.text}
                  </a>
                </nav>
              </div>
            </aside>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
