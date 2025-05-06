defmodule CuratorianWeb.DashboardLive.OrgsLive.Create do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Orgs
  alias Curatorian.Orgs.Organization

  def render(assigns) do
    ~H"""
    <.header>
      Create New Organization
    </.header>

    <.back navigate="/dashboard/orgs">Kembali</.back>

    <section>
      <.simple_form for={@form} phx-submit="save">
        <.input field={@form[:name]} label="Nama Organisasi" type="text" />
        <.input field={@form[:description]} label="Deskripsi" type="textarea" />
        <.input field={@form[:website]} label="Website" type="text" />
        <.input field={@form[:email]} label="Email" type="text" />
        <.input field={@form[:phone_number]} label="Nomor Telepon" type="text" />
        <.button>Save Changes</.button>
      </.simple_form>
    </section>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Orgs.change_organization(%Organization{})

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:form, changeset)

    {:ok, socket}
  end

  def handle_event("validate", %{"organization" => organization_params}, socket) do
    changeset =
      socket.assigns.changeset
      |> Organization.changeset(organization_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"organization" => organization_params}, socket) do
    case Orgs.create_organization(organization_params) do
      {:ok, _org} ->
        {:noreply, push_patch(socket, to: "/dashboard/orgs")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
