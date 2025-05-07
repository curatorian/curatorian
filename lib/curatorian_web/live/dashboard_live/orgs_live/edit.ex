defmodule CuratorianWeb.DashboardLive.OrgsLive.Edit do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Orgs
  alias Curatorian.Orgs.Organization

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>
      Edit Organization
      <:subtitle>Use this form to manage organization records in your database.</:subtitle>
    </.header>

    <.back navigate="/dashboard/orgs">Kembali</.back>

    <section>
      <.live_component
        module={CuratorianWeb.DashboardLive.OrgsLive.OrganizationForm}
        id={@organization.id}
        organization={@organization}
        title="Edit Organization"
        navigate={~p"/dashboard/orgs"}
        action={:edit}
      />
      <.back navigate="/dashboard/orgs">Kembali</.back>
    </section>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"slug" => slug}, _session, socket) do
    organization = Orgs.get_organization_by_slug(slug)
    user_profile = socket.assigns.current_user
    user_id = socket.assigns.current_user.id

    if organization.user_id == user_id do
      changeset = Orgs.change_organization(%Organization{})

      socket =
        socket
        |> assign(:changeset, changeset)
        |> assign(:organization, organization)
        |> assign(:user_id, user_id)
        |> assign(:user_profile, user_profile)

      {:ok, socket}
    else
      {:error, :not_found}
    end
  end
end
