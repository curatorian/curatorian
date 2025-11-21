defmodule CuratorianWeb.DashboardLive.BlogsLive.Form do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Blogs
  alias Curatorian.Blogs.Blog
  alias Curatorian.Repo
  alias CuratorianWeb.Utils.Slugify

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="blog-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          prompt="Pilih Status Publikasi"
          options={@status_input}
        /> <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:slug]} type="text" label="Slug" phx-hook="Slugify" id="slug" />
        <.input field={@form[:summary]} type="text" label="Summary" />
        <.input
          type="text"
          label="Tags"
          placeholder="e.g. Art, History, Tech"
          field={@form[:tag_name]}
          phx-hook="ChooseTag"
          phx-target={@myself}
          autocomplete="off"
        />
        <div class="flex gap-2">
          <%= for tag <- @tags do %>
            <div
              class="bg-purple-500 text-white px-4 py-1 rounded-lg text-sm -mt-6 cursor-pointer"
              phx-click="delete_tag"
              phx-target={@myself}
              phx-value-tag-slug={tag.slug}
            >
              {tag.name}
            </div>
          <% end %>
        </div>
        
        <div>
          <label>Konten</label>
          <.input
            field={@form[:content]}
            id="article-content"
            type="hidden"
            phx-hook="Trix"
            phx-debounce="blur"
          />
          <div id="trix-editor-container" phx-update="ignore">
            <trix-editor input="article-content"></trix-editor>
          </div>
        </div>
        
        <div>
          <.input field={@form[:image_url]} type="hidden" label="Thumbnail" />
          <section phx-drop-target={@uploads.thumbnail.ref}>
            <%= if length(@uploads.thumbnail.entries) === 0 do %>
              <img src={@blog.image_url} class="max-h-[320px] object-cover" />
            <% end %>
             <%!-- render each thumbnail entry --%>
            <article :for={entry <- @uploads.thumbnail.entries} class="upload-entry">
              <figure>
                <.live_img_preview entry={entry} class="w-full max-h-[120px] object-cover" />
                <figcaption>{entry.client_name}</figcaption>
              </figure>
               <%!-- entry.progress will update automatically for in-flight entries --%>
              <progress value={entry.progress} max="100">{entry.progress}%</progress>
              <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                aria-label="cancel"
                phx-target={@myself}
              >
                &times;
              </button> <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
              <p :for={err <- upload_errors(@uploads.thumbnail, entry)} class="alert alert-danger">
                {error_to_string(err)}
              </p>
            </article>
             <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
            <p :for={err <- upload_errors(@uploads.thumbnail)} class="alert alert-danger">
              {error_to_string(err)}
            </p>
          </section>
           <.live_file_input upload={@uploads.thumbnail} />
        </div>
        
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Blog</.button>
          <.button navigate={return_path(@return_to, @blog)}>Cancel</.button>
        </footer>
      </.form>
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
    user_id = socket.assigns[:user_id]
    user_profile = socket.assigns[:user_profile] || socket.assigns[:current_user]

    privileged_roles = ["manager", "admin", "coordinator"]

    authorized =
      (user_id && blog.user_id == user_id) or
        (user_profile && Map.get(user_profile, :user_role) in privileged_roles)

    if authorized do
      socket
      |> assign(:title, "Edit Blog")
      |> assign(:blog, blog)
      |> assign(:tags, blog.tags)
      |> assign(:categories, blog.categories)
      |> assign(:form, to_form(Blogs.change_blog(blog)))
    else
      socket
      |> put_flash(:error, "You are not authorized to edit this blog.")
      |> push_navigate(to: ~p"/dashboard/blogs")
    end
  end

  defp apply_action(socket, :new, _params) do
    blog = %Blog{}

    socket
    |> assign(:title, "New Blog")
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
      consume_uploaded_entries(socket, :thumbnail, fn %{path: path}, _entry ->
        dest_dir = Application.app_dir(:curatorian, "priv/static/uploads/thumbnail")

        dest =
          Path.join(
            dest_dir,
            Path.basename(path)
          )

        File.mkdir_p!(dest_dir)

        File.cp!(path, dest)

        image_path = "/uploads/thumbnail/#{Path.basename(path)}"
        {:ok, image_path}
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

    save_blog(socket, socket.assigns.action, blog_params)
  end

  defp save_blog(socket, :edit, blog_params) do
    user_id = socket.assigns.user_id

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
    user_id = socket.assigns.user_id

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

  defp return_path("index", _blog), do: ~p"/dashboard/blogs"
  defp return_path("show", blog), do: ~p"/dashboard/blogs/#{blog}"
end
