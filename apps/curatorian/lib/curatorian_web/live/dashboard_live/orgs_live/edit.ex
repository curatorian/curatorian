defmodule CuratorianWeb.DashboardLive.OrgsLive.Edit do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Orgs

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>
      Edit Organization
      <:subtitle>Use this form to manage organization records in your database.</:subtitle>
    </.header>
    <.button navigate="/dashboard/orgs">Kembali</.button>
    <section>
      <.live_component
        module={CuratorianWeb.DashboardLive.OrgsLive.OrganizationForm}
        id={@organization.id}
        organization={@organization}
        current_user={@current_scope.user}
        title="Edit Organization"
        navigate={~p"/dashboard/orgs"}
        action={:edit}
      />
    </section>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"slug" => slug}, session, socket) do
    current_user = socket.assigns.current_scope.user || session["current_user"]
    current_user = Curatorian.Repo.preload(current_user, :roles)
    organization = Orgs.get_organization_by_slug(slug)

    if Orgs.has_permission?(organization, current_user, :manage_all) do
      {:ok,
       socket
       |> assign(:current_user, current_user)
       |> assign(:organization, organization)
       |> allow_upload(:profile_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)
       |> allow_upload(:cover_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
    else
      {:ok,
       socket
       |> put_flash(:error, "You don't have permission to edit this organization")
       |> push_navigate(to: ~p"/dashboard/orgs/#{slug}")}
    end
  end
end
