defmodule CuratorianWeb.DashboardLive.BlogsLive.BlogForm do
  use CuratorianWeb, :live_component

  alias Curatorian.Blogs

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
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
        />
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:slug]} type="text" label="Slug" phx-hook="Slugify" id="slug" />
        <.input field={@form[:summary]} type="text" label="Summary" />
        <%!-- <.input field={@form[:content]} type="text" label="Content" /> --%>
        <div>
          <.label>Trix</.label>

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
              <img src={@blog.image_url} class="w-full max-h-[320px] object-cover" />
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
              </button>
              <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
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

        <:actions>
          <.button type="submit" phx-disable-with="Saving...">Save Blog</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{blog: blog} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:content, blog.content)
     |> assign(:status_input, status_input())
     |> assign_new(:form, fn ->
       to_form(Blogs.change_blog(blog))
     end)
     |> assign(:uploaded_files, [])
     |> allow_upload(:thumbnail,
       accept: ~w(.jpg .jpeg .png),
       max_files: 1,
       max_file_size: 3_000_000,
       auto_upload: true
     )}
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

    blog_params =
      if length(uploaded_files) > 0 do
        Map.put(blog_params, "image_url", hd(uploaded_files))
      else
        blog_params
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
      # |> Map.put("content", socket.assigns.content)
      |> Map.put("user_id", user_id)
      |> sanitize_html()

    case Blogs.update_blog(socket.assigns.blog, blog_params) do
      {:ok, blog} ->
        notify_parent({:saved, blog})

        {:noreply,
         socket
         |> put_flash(:info, "Blog updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp save_blog(socket, :new, blog_params) do
    user_id = socket.assigns.user_id

    blog_params =
      blog_params
      |> Map.put("user_id", user_id)
      # |> Map.put("content", socket.assigns.content)
      |> sanitize_html()

    case Blogs.create_blog(blog_params) do
      {:ok, blog} ->
        notify_parent({:saved, blog})

        {:noreply,
         socket
         |> put_flash(:info, "Blog created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

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
end
