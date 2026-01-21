defmodule CuratorianWeb.CommentLive.Index do
  use CuratorianWeb, :live_view

  alias Curatorian.Comments

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Comments
        <:actions>
          <.button variant="primary" navigate={~p"/comments/new"}>
            <.icon name="hero-plus" /> New Comment
          </.button>
        </:actions>
      </.header>

      <.table
        id="comments"
        rows={@streams.comments}
        row_click={fn {_id, comment} -> JS.navigate(~p"/comments/#{comment}") end}
      >
        <:col :let={{_id, comment}} label="Content">{comment.content}</:col>

        <:action :let={{_id, comment}}>
          <div class="sr-only"><.link navigate={~p"/comments/#{comment}"}>Show</.link></div>
          <.link navigate={~p"/comments/#{comment}/edit"}>Edit</.link>
        </:action>

        <:action :let={{id, comment}}>
          <.link
            phx-click={JS.push("delete", value: %{id: comment.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page_title: "Listing Comments")
      |> stream(:comments, list_comments())

    {:ok, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    comment = Comments.get_comment!(id)
    {:ok, _} = Comments.delete_comment(comment)

    {:noreply, stream_delete(socket, :comments, comment)}
  end

  defp list_comments do
    Comments.list_comments()
  end
end
