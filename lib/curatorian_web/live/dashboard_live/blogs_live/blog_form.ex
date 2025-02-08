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
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:slug]} type="text" label="Slug" />
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
         <.input field={@form[:image_url]} type="text" label="Image url" />
        <.input field={@form[:status]} type="text" label="Status" />
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
     |> assign_new(:form, fn ->
       to_form(Blogs.change_blog(blog))
     end)}
  end

  @impl true
  def handle_event("validate", %{"blog" => blog_params}, socket) do
    changeset =
      socket.assigns.blog
      |> Blogs.change_blog(blog_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("trix-change", %{"content" => content}, socket) do
    {:noreply, assign(socket, :content, content)}
  end

  def handle_event("save", %{"blog" => blog_params}, socket) do
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
end
