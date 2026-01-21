defmodule CuratorianWeb.OrgsHTML do
  use CuratorianWeb, :html

  embed_templates "*"

  @doc """
  Renders a orgs form.

  The form is defined in the template at
  orgs_html/orgs_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil

  def orgs_form(assigns)

  # Helper functions for organization views
  def organization_status_badge(status) do
    case status do
      "draft" -> "bg-gray-200 text-gray-700"
      "pending" -> "bg-yellow-200 text-yellow-700"
      "approved" -> "bg-green-200 text-green-700"
      "archived" -> "bg-red-200 text-red-700"
      _ -> "bg-gray-200 text-gray-700"
    end
  end

  def organization_type_label(type) do
    case type do
      "company" -> "Company"
      "institution" -> "Institution"
      "community" -> "Community"
      "non_profit" -> "Non-profit Organization"
      _ -> type
    end
  end

  def role_badge_color(role) do
    case role do
      "owner" -> "bg-purple-100 text-purple-800"
      "admin" -> "bg-blue-100 text-blue-800"
      "editor" -> "bg-green-100 text-green-800"
      "member" -> "bg-gray-100 text-gray-800"
      "guest" -> "bg-yellow-100 text-yellow-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  def format_date(datetime) when is_nil(datetime), do: ""

  def format_date(datetime) do
    datetime
    |> Calendar.strftime("%B %d, %Y")
  end

  def is_member?(organization, user) do
    Curatorian.Orgs.get_user_role(organization, user) != :guest
  end

  def is_owner?(organization, user) do
    Curatorian.Orgs.get_user_role(organization, user) == "owner"
  end

  def can_manage?(organization, user) do
    Curatorian.Orgs.has_permission?(organization, user, :manage_all)
  end
end
