defmodule CuratorianWeb.DashboardLive.OrgsLive.OrganizationForm do
  use CuratorianWeb, :live_component

  alias Curatorian.Orgs
  # alias Curatorian.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@org_form}
        id="organization-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.input field={@org_form[:name]} type="text" label="Name" />
        <.input field={@org_form[:slug]} type="text" label="Slug" phx-hook="Slugify" id="slug" />
        <.input
          field={@org_form[:status]}
          type="select"
          label="Status"
          options={["draft", "pending", "approved", "archived"]}
        />
        <.input
          field={@org_form[:type]}
          type="select"
          label="Type"
          options={["company", "institution", "community", "non_profit"]}
        /> <.input field={@org_form[:description]} type="textarea" label="Description" />
        <:actions>
          <.button type="submit" phx-disable-with="Saving...">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{organization: organization, action: action} = assigns, socket) do
    changeset = Orgs.change_organization(organization)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign(:action, action)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @impl true
  def handle_event("validate", %{"organization" => organization_params}, socket) do
    changeset =
      socket.assigns.organization
      |> Orgs.change_organization(organization_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"organization" => organization_params}, socket) do
    save_organization(socket, socket.assigns.action, organization_params)
  end

  defp save_organization(socket, :edit, organization_params) do
    case Orgs.update_organization(socket.assigns.organization, organization_params) do
      {:ok, organization} ->
        notify_parent({:saved, organization})

        {:noreply,
         socket
         |> put_flash(:info, "Organization updated successfully")
         |> push_patch(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_organization(socket, :new, organization_params) do
    case Orgs.create_organization(socket.assigns.current_user, organization_params) do
      {:ok, organization} ->
        notify_parent({:saved, organization})

        {:noreply,
         socket
         |> put_flash(:info, "Organization created successfully")
         |> push_navigate(to: ~p"/dashboard/orgs/#{organization.slug}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
