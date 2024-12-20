defmodule CuratorianWeb.BlogHTML do
  use CuratorianWeb, :html

  embed_templates "blog_html/*"

  @doc """
  Renders a blog form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def blog_form(assigns)
end
