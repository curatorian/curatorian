defmodule CuratorianWeb.CommentLive.Show do
  use CuratorianWeb, :live_view

  alias Curatorian.Comments

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Comment {@comment.id}
        <:subtitle>This is a comment record from your database.</:subtitle>

        <:actions>
          <.button navigate={~p"/comments"}><.icon name="hero-arrow-left" /></.button>
          <.button variant="primary" navigate={~p"/comments/#{@comment}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit comment
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Content">{@comment.content}</:item>
      </.list>
      <.button navigate={~p"/comments"}><.icon name="hero-arrow-left" /></.button>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    comment = Comments.get_comment!(id)

    socket =
      socket
      |> assign(:page_title, "Show Comment")
      |> assign(:comment, comment)

    {:ok, socket}
  end
end
