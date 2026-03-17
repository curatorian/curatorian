defmodule CuratorianWeb.Public.BlogShowLive do
  @moduledoc "Public view of a single blog post with comments."

  use CuratorianWeb, :live_view

  alias Curatorian.Public
  alias CuratorianWeb.Markdown

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"username" => username, "slug" => slug}, _uri, socket) do
    case Public.get_public_blog_post(username, slug) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Artikel tidak ditemukan.")
         |> push_navigate(to: ~p"/u/#{username}")}

      post ->
        author = Public.get_public_profile(username)
        comments = Public.list_public_comments(post.id)
        comment_form = to_form(%{"body" => ""}, as: :comment)

        {:noreply,
         socket
         |> assign(:page_title, post.title)
         |> assign(:post, post)
         |> assign(:author, author)
         |> assign(:username, username)
         |> assign(:comment_form, comment_form)
         |> stream(:comments, comments)}
    end
  end

  @impl true
  def handle_event("submit_comment", %{"comment" => %{"body" => body}}, socket) do
    post = socket.assigns.post
    user = socket.assigns.current_scope && socket.assigns.current_scope.user

    unless user do
      {:noreply,
       socket
       |> put_flash(:error, "Anda harus masuk untuk berkomentar.")
       |> redirect(to: ~p"/login")}
    else
      body = String.trim(body)

      cond do
        body == "" ->
          {:noreply, put_flash(socket, :error, "Komentar tidak boleh kosong.")}

        String.length(body) > 5000 ->
          {:noreply, put_flash(socket, :error, "Komentar terlalu panjang (maks. 5000 karakter).")}

        true ->
          case Public.create_blog_comment(post.id, user, body) do
            {:ok, comment} ->
              form = to_form(%{"body" => ""}, as: :comment)

              {:noreply,
               socket
               |> assign(:post, %{post | comment_count: post.comment_count + 1})
               |> assign(:comment_form, form)
               |> stream_insert(:comments, comment)
               |> put_flash(:info, "Komentar berhasil ditambahkan.")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Gagal mengirim komentar.")}
          end
      end
    end
  end

  defp format_date(nil), do: "—"
  defp format_date(dt), do: Calendar.strftime(dt, "%d %B %Y")

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto py-8 px-4 pb-16">
        <%!-- Breadcrumb --%>
        <div class="flex items-center gap-2 text-sm text-base-content/50 mb-6 flex-wrap">
          <.link navigate={~p"/kurator"} class="hover:text-primary transition-colors">
            Kurator
          </.link>
          <.icon name="hero-chevron-right-micro" class="w-3 h-3" />
          <.link navigate={~p"/u/#{@username}"} class="hover:text-primary transition-colors">
            {(@author && @author.display_name) || @username}
          </.link>
          <.icon name="hero-chevron-right-micro" class="w-3 h-3" />
          <span class="truncate max-w-xs">{@post.title}</span>
        </div>

        <%!-- Cover image --%>
        <div
          :if={@post.cover_url && @post.cover_url != ""}
          class="rounded-2xl overflow-hidden mb-8 h-60 md:h-80"
        >
          <img
            src={asset_url(@post.cover_url)}
            alt={@post.title}
            class="w-full h-full object-cover"
          />
        </div>

        <%!-- Tags --%>
        <div :if={@post.tags != []} class="flex flex-wrap gap-1.5 mb-4">
          <%= for tag <- @post.tags do %>
            <span class="badge badge-outline badge-sm">{tag}</span>
          <% end %>
        </div>

        <%!-- Title --%>
        <h1 class="text-3xl md:text-4xl font-bold leading-tight mb-4">{@post.title}</h1>

        <%!-- Author + date --%>
        <div class="flex items-center gap-3 mb-8 pb-6 border-b border-base-300">
          <%= if @author do %>
            <.link navigate={~p"/u/#{@username}"} class="flex items-center gap-3 group">
              <div class="w-10 h-10 rounded-full overflow-hidden bg-violet-200 dark:bg-violet-800 shrink-0">
                <%= if @author.avatar_url do %>
                  <img
                    src={asset_url(@author.avatar_url)}
                    alt={@author.display_name}
                    class="w-full h-full object-cover"
                  />
                <% else %>
                  <div class="w-full h-full flex items-center justify-center">
                    <span class="text-sm font-bold text-violet-600 dark:text-violet-300">
                      {String.first(@author.display_name || "K")}
                    </span>
                  </div>
                <% end %>
              </div>
              <div>
                <p class="font-semibold text-sm group-hover:text-primary transition-colors">
                  {@author.display_name}
                </p>
                <p :if={@author.headline} class="text-xs text-base-content/50">{@author.headline}</p>
              </div>
            </.link>
          <% end %>
          <div class="ml-auto text-right">
            <p class="text-sm text-base-content/50">{format_date(@post.published_at)}</p>
            <p class="text-xs text-base-content/40">
              {if @post.comment_count > 0,
                do: "#{@post.comment_count} komentar",
                else: "Belum ada komentar"}
            </p>
          </div>
        </div>

        <%!-- Post body --%>
        <div class="prose prose-base max-w-none">
          {Markdown.to_html(@post.body)}
        </div>

        <%!-- Comments section --%>
        <%= if @post.is_comments_enabled do %>
          <div class="mt-14 border-t border-base-300 pt-10">
            <h2 class="text-xl font-bold mb-6">
              Komentar
              <span class="text-base-content/40 font-normal text-base ml-1">
                ({@post.comment_count})
              </span>
            </h2>

            <%!-- Comment form: logged in --%>
            <%= if @current_scope && @current_scope.user do %>
              <div class="card bg-base-200/60 rounded-xl p-5 mb-8">
                <p class="text-sm font-medium mb-3">
                  Berkomentar sebagai
                  <span class="font-bold">
                    {@current_scope.user.fullname || @current_scope.user.username}
                  </span>
                </p>
                <.form
                  for={@comment_form}
                  id="comment-form"
                  phx-submit="submit_comment"
                  class="space-y-3"
                >
                  <.input
                    field={@comment_form[:body]}
                    type="textarea"
                    placeholder="Tulis komentar Anda..."
                    rows={4}
                  />
                  <button type="submit" class="btn btn-primary btn-sm">
                    Kirim Komentar
                  </button>
                </.form>
              </div>
            <% else %>
              <%!-- Comment form: not logged in --%>
              <div class="card bg-base-200/60 rounded-xl p-5 mb-8 text-center">
                <p class="text-sm text-base-content/60">
                  <.link navigate={~p"/login"} class="text-primary font-medium hover:underline">
                    Masuk
                  </.link>
                  untuk meninggalkan komentar.
                </p>
              </div>
            <% end %>

            <%!-- Comment list --%>
            <div id="comments" class="space-y-5" phx-update="stream">
              <div :for={{id, comment} <- @streams.comments} id={id} class="flex gap-3">
                <%!-- Avatar --%>
                <div class="w-9 h-9 rounded-full overflow-hidden bg-base-300 shrink-0 mt-0.5">
                  <%= if comment.author_avatar_url && comment.author_avatar_url != "" do %>
                    <img
                      src={asset_url(comment.author_avatar_url)}
                      alt={comment.author_display_name}
                      class="w-full h-full object-cover"
                    />
                  <% else %>
                    <div class="w-full h-full bg-violet-100 dark:bg-violet-900 flex items-center justify-center">
                      <span class="text-xs font-bold text-violet-600 dark:text-violet-300">
                        {String.first(comment.author_display_name || "?")}
                      </span>
                    </div>
                  <% end %>
                </div>

                <%!-- Comment body --%>
                <div class="flex-1 bg-base-100 rounded-xl p-4 border border-base-300">
                  <div class="flex items-center gap-2 mb-1.5">
                    <.link
                      navigate={~p"/u/#{comment.author_username}"}
                      class="font-semibold text-sm hover:text-primary transition-colors"
                    >
                      {comment.author_display_name}
                    </.link>
                    <span class="text-xs text-base-content/40">
                      {format_date(comment.inserted_at)}
                    </span>
                  </div>
                  <p class="text-sm text-base-content/80 leading-relaxed whitespace-pre-wrap">
                    {comment.body}
                  </p>
                </div>
              </div>
            </div>
          </div>
        <% end %>

        <%!-- Back to profile link --%>
        <div class="mt-14 pt-8 border-t border-base-300">
          <.link
            navigate={~p"/u/#{@username}"}
            class="inline-flex items-center gap-2 text-sm text-base-content/60 hover:text-primary transition-colors"
          >
            <.icon name="hero-arrow-left" class="w-4 h-4" />
            Kembali ke profil {(@author && @author.display_name) || @username}
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
