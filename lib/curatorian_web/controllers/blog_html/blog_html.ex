defmodule CuratorianWeb.BlogHTML do
  use CuratorianWeb, :html

  embed_templates "*"

  @doc """
  Renders a blog form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def blog_form(assigns)
end
