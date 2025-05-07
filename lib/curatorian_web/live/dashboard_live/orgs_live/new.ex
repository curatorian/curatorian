defmodule CuratorianWeb.DashboardLive.OrgsLive.New do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Orgs
  alias Curatorian.Orgs.Organization

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>
      Create New Organization
      <:subtitle>Use this form to manage organization records in your database.</:subtitle>
    </.header>

    <.back navigate="/dashboard/orgs">Kembali</.back>

    <section>
      <.live_component
        module={CuratorianWeb.DashboardLive.OrgsLive.OrganizationForm}
        id={@organization.id || :new}
        organization={@organization}
        title="New Organization"
        navigate={~p"/dashboard/orgs"}
        action={:new}
      />
      <.back navigate="/dashboard/orgs">Kembali</.back>
    </section>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    changeset = Orgs.change_organization(%Organization{})

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:organization, %Organization{})

    {:ok, socket}
  end
end
