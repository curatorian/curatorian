defmodule CuratorianWeb.CommentLive.Form do
  use CuratorianWeb, :live_view

  alias Curatorian.Comments
  alias Curatorian.Comments.Comment

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage comment records in your database.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="comment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:content]} type="text" label="Content" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Comment</.button>
          <.button navigate={return_path(@return_to, @comment)}>Cancel</.button>
        </footer>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:return_to, return_to(params["return_to"]))
      |> apply_action(socket.assigns.live_action, params)

    {:ok, socket}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    comment = Comments.get_comment!(id)

    socket
    |> assign(:title, "Edit Comment")
    |> assign(:comment, comment)
    |> assign(:form, to_form(Comments.change_comment(comment)))
  end

  defp apply_action(socket, :new, _params) do
    comment = %Comment{}

    socket
    |> assign(:title, "New Comment")
    |> assign(:comment, comment)
    |> assign(:form, to_form(Comments.change_comment(comment)))
  end

  @impl true
  def handle_event("validate", %{"comment" => comment_params}, socket) do
    changeset = Comments.change_comment(socket.assigns.comment, comment_params)

    socket =
      socket
      |> assign(form: to_form(changeset, action: :validate))

    {:noreply, socket}
  end

  def handle_event("save", %{"comment" => comment_params}, socket) do
    save_comment(socket, socket.assigns.live_action, comment_params)
  end

  defp save_comment(socket, :edit, comment_params) do
    case Comments.update_comment(socket.assigns.comment, comment_params) do
      {:ok, comment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Comment updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, comment))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_comment(socket, :new, comment_params) do
    case Comments.create_comment(comment_params) do
      {:ok, comment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Comment created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, comment))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _post), do: ~p"/comments"
  defp return_path("show", comment), do: ~p"/comments/#{comment}"
end
