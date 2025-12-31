defmodule CuratorianWeb.DashboardLive.BlogsLive.Form do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Blogs
  alias Curatorian.Blogs.Blog
  alias Curatorian.Repo
  alias CuratorianWeb.Utils.Slugify

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto">
      <.header>
        {@title}
        <:subtitle>
          {if @action == :new, do: "Create a new blog post", else: "Update your blog post"}
        </:subtitle>
      </.header>
      
      <div class="mt-6 bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 md:p-8">
        <.form
          for={@form}
          id="blog-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-8"
        >
          <%!-- Basic Information --%>
          <section>
            <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
              Basic Information
            </h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="md:col-span-2">
                <.input field={@form[:title]} type="text" label="Title" required />
              </div>
               <.input field={@form[:slug]} type="text" label="Slug" phx-hook="Slugify" id="slug" />
              <.input
                field={@form[:status]}
                type="select"
                label="Status"
                prompt="Select publication status"
                options={@status_input}
              />
              <div class="md:col-span-2">
                <.input field={@form[:summary]} type="textarea" label="Summary" rows="3" />
              </div>
            </div>
          </section>
           <%!-- Tags --%>
          <section>
            <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">Tags</h3>
            
            <.input
              type="text"
              label="Add Tags"
              placeholder="e.g. Art, History, Tech"
              field={@form[:tag_name]}
              phx-hook="ChooseTag"
              autocomplete="off"
            />
            <%= if @tags != [] do %>
              <div class="flex flex-wrap gap-2 mt-3">
                <%= for tag <- @tags do %>
                  <span
                    class="inline-flex items-center gap-2 bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200 px-3 py-1 rounded-full text-sm font-medium cursor-pointer hover:bg-purple-200 dark:hover:bg-purple-800 transition-colors"
                    phx-click="delete_tag"
                    phx-value-tag-slug={tag.slug}
                  >
                    {tag.name} <.icon name="hero-x-mark" class="w-4 h-4" />
                  </span>
                <% end %>
              </div>
            <% end %>
          </section>
           <%!-- Thumbnail --%>
          <section>
            <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
              Thumbnail Image
            </h3>
             <.input field={@form[:image_url]} type="hidden" />
            <div
              phx-drop-target={@uploads.thumbnail.ref}
              class="border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg p-6 hover:border-gray-400 dark:hover:border-gray-500 transition-colors"
            >
              <%= if length(@uploads.thumbnail.entries) === 0 do %>
                <%= if @blog.image_url do %>
                  <div class="relative group">
                    <img src={@blog.image_url} class="w-full max-h-64 object-cover rounded-lg" />
                    <div class="absolute inset-0 bg-black bg-opacity-50 opacity-0 group-hover:opacity-100 transition-opacity rounded-lg flex items-center justify-center">
                      <p class="text-white text-sm">Click or drag to replace</p>
                    </div>
                  </div>
                <% else %>
                  <div class="text-center py-8">
                    <.icon name="hero-photo" class="w-12 h-12 mx-auto text-gray-400 mb-3" />
                    <p class="text-sm text-gray-600 dark:text-gray-400 mb-1">
                      Drop your image here or click to browse
                    </p>
                    
                    <p class="text-xs text-gray-500 dark:text-gray-500">JPG, JPEG or PNG (max 3MB)</p>
                  </div>
                <% end %>
              <% end %>
              
              <%= for entry <- @uploads.thumbnail.entries do %>
                <div class="relative">
                  <.live_img_preview entry={entry} class="w-full max-h-64 object-cover rounded-lg" />
                  <div class="mt-2 flex items-center justify-between">
                    <span class="text-sm text-gray-600 dark:text-gray-400">{entry.client_name}</span>
                    <button
                      type="button"
                      phx-click="cancel-upload"
                      phx-value-ref={entry.ref}
                      class="text-red-600 hover:text-red-700 dark:text-red-400"
                    >
                      <.icon name="hero-x-mark" class="w-5 h-5" />
                    </button>
                  </div>
                  
                  <progress value={entry.progress} max="100" class="w-full mt-2">
                    {entry.progress}%
                  </progress>
                  <p
                    :for={err <- upload_errors(@uploads.thumbnail, entry)}
                    class="text-sm text-red-600 mt-1"
                  >
                    {error_to_string(err)}
                  </p>
                </div>
              <% end %>
              
              <p :for={err <- upload_errors(@uploads.thumbnail)} class="text-sm text-red-600 mt-2">
                {error_to_string(err)}
              </p>
            </div>
             <.live_file_input upload={@uploads.thumbnail} class="mt-3" />
          </section>
           <%!-- Content Editor --%>
          <section>
            <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">Content</h3>
            
            <.input
              field={@form[:content]}
              id="article-content"
              type="hidden"
              phx-hook="Trix"
              phx-debounce="blur"
            />
            <div
              id="trix-editor-container"
              phx-update="ignore"
              class="border border-gray-300 dark:border-gray-600 rounded-lg overflow-hidden"
            >
              <trix-editor input="article-content" class="min-h-[400px]"></trix-editor>
            </div>
          </section>
           <%!-- Action Buttons --%>
          <div class="flex items-center justify-between pt-6 border-t border-gray-200 dark:border-gray-700">
            <.button
              type="button"
              navigate={return_path(@return_to, @blog)}
              class="btn-secondary"
            >
              <.icon name="hero-x-mark" class="w-4 h-4 mr-2" /> Cancel
            </.button>
            <.button type="submit" phx-disable-with="Saving...">
              <.icon name="hero-check" class="w-4 h-4 mr-2" /> {if @action == :new,
                do: "Create Blog",
                else: "Update Blog"}
            </.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    blog =
      %Blog{}
      |> Repo.preload(:tags)
      |> Repo.preload(:categories)

    socket =
      socket
      |> assign(:content, blog.content)
      |> assign(:status_input, status_input())
      |> assign(:uploaded_files, [])
      |> assign(:return_to, return_to(params["return_to"]))
      |> apply_action(socket.assigns.live_action, params)
      |> allow_upload(:thumbnail,
        accept: ~w(.jpg .jpeg .png),
        max_files: 1,
        max_file_size: 3_000_000,
        auto_upload: true
      )

    {:ok, socket}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    blog = Blogs.get_blog_by_slug(slug) |> Repo.preload(:tags) |> Repo.preload(:categories)

    # Authorization: only the blog owner or privileged users can edit
    user_id = socket.assigns.current_scope.user.id
    user_profile = socket.assigns.current_scope.user.profile || socket.assigns.current_scope.user

    privileged_roles = ["manager", "admin", "coordinator"]

    authorized =
      (user_id && blog.user_id == user_id) or
        (user_profile && Map.get(user_profile, :user_role) in privileged_roles)

    if authorized do
      socket
      |> assign(:title, "Edit Blog")
      |> assign(:action, :edit)
      |> assign(:blog, blog)
      |> assign(:tags, blog.tags)
      |> assign(:categories, blog.categories)
      |> assign(:form, to_form(Blogs.change_blog(blog)))
    else
      socket
      |> put_flash(:error, "You are not authorized to edit this blog.")
      |> push_navigate(to: ~p"/dashboard/blog")
    end
  end

  defp apply_action(socket, :new, _params) do
    blog = %Blog{}

    socket
    |> assign(:title, "New Blog")
    |> assign(:action, :new)
    |> assign(:blog, blog)
    |> assign(:tags, [])
    |> assign(:categories, [])
    |> assign(:form, to_form(Blogs.change_blog(blog)))
  end

  @impl true
  def handle_event("validate", %{"blog" => blog_params}, socket) do
    changeset =
      socket.assigns.blog
      |> Blogs.change_blog(blog_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("trix-change", %{"content" => content}, socket) do
    {:noreply, assign(socket, :content, content)}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    send(self(), {:cancel_upload})
    {:noreply, cancel_upload(socket, :thumbnail, ref)}
  end

  @impl true
  def handle_event("add_tag", %{"name" => tag_name}, socket) do
    new_tag = %{
      name: tag_name,
      slug: Slugify.slugify(tag_name)
    }

    updated_tags =
      socket.assigns.tags
      |> Enum.reject(&(&1.slug == new_tag.slug))
      |> Kernel.++([new_tag])

    {:noreply, assign(socket, tags: updated_tags)}
  end

  @impl true
  def handle_event("delete_tag", %{"tag-slug" => tag_slug}, socket) do
    changeset =
      socket.assigns.blog
      |> Blogs.change_blog(%{"tag_name" => ""})

    form = to_form(changeset, action: :validate)

    socket =
      socket
      |> assign(form: form)
      |> update(:tags, fn tags ->
        Enum.reject(tags, fn tag -> tag.slug == tag_slug end)
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"blog" => blog_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :thumbnail, fn %{path: path}, entry ->
        case Clients.Storage.adapter().upload_from_path(path, entry.client_type, "thumbnail") do
          {:ok, image_path} -> {:ok, image_path}
          {:error, _} -> {:error, "Failed to upload"}
        end
      end)

    tags = socket.assigns.tags
    categories = socket.assigns.categories

    chosen_tags =
      tags
      |> Enum.map(fn tag ->
        # Validate tag
        if is_map(tag) and Map.has_key?(tag, :name) and Map.has_key?(tag, :slug) do
          case Blogs.get_or_create_tag(tag) do
            {:ok, tag} ->
              tag

            {:error, changeset} ->
              dbg("Error creating tag: #{inspect(changeset)}")
              nil
          end
        else
          dbg("Invalid tag data: #{inspect(tag)}")
          nil
        end
      end)

    blog_params =
      if length(uploaded_files) > 0 do
        blog_params
        |> Map.put("image_url", hd(uploaded_files))
        |> Map.put("tags", chosen_tags)
        |> Map.put("categories", categories)
      else
        blog_params
        |> Map.put("tags", chosen_tags)
        |> Map.put("categories", categories)
      end

    socket =
      socket
      |> update(:uploaded_files, &(&1 ++ uploaded_files))

    action = Map.get(socket.assigns, :action, socket.assigns.live_action || :new)

    save_blog(socket, action, blog_params)
  end

  defp save_blog(socket, :edit, blog_params) do
    user_id = socket.assigns.current_scope.user.id

    blog_params =
      blog_params
      |> Map.put("user_id", user_id)
      |> sanitize_html()

    case Blogs.update_blog(socket.assigns.blog, blog_params) do
      {:ok, blog} ->
        {:noreply,
         socket
         |> put_flash(:info, "Blog updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, blog))}

      {:error, changeset} ->
        dbg(changeset)
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp save_blog(socket, :new, blog_params) do
    user_id = socket.assigns.current_scope.user.id

    blog_params =
      blog_params
      |> Map.put("user_id", user_id)
      |> sanitize_html()

    case Blogs.create_blog(blog_params) do
      {:ok, blog} ->
        {:noreply,
         socket
         |> put_flash(:info, "Blog created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, blog))}

      {:error, changeset} ->
        dbg(changeset)
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp sanitize_html(attrs) do
    html = Map.get(attrs, "content", "")
    safe_html = HtmlSanitizeEx.basic_html(html)
    Map.put(attrs, "content", safe_html)
  end

  defp status_input do
    [
      {"Draft", "draft"},
      {"Published", "published"},
      {"Archived", "archived"}
    ]
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"

  defp return_path("index", _blog), do: ~p"/dashboard/blog"
  defp return_path("show", blog), do: ~p"/dashboard/blog/#{blog}"
end
