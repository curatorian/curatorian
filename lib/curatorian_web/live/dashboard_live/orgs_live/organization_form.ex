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
          options={["company", "community", "non-profit"]}
        /> <.input field={@org_form[:description]} type="textarea" label="Description" />
        <.input field={@org_form[:slug]} type="text" label="Slug" phx-hook="Slugify" id="slug" />
        <:actions>
          <.button type="submit" phx-disable-with="Saving...">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset = Orgs.change_organization(assigns.organization)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:org_form, fn ->
       to_form(changeset, as: :org_form)
     end)}
  end

  @impl true
  def handle_event("validate", %{"org_form" => org_params}, socket) do
    changeset =
      socket.assigns.organization
      |> Orgs.change_organization(org_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:org_form, to_form(changeset, as: :org_form))}
  end

  @impl true
  def handle_event("save", %{"org_form" => org_params}, socket) do
    save_organization(socket, socket.assigns.action, org_params)
  end

  defp save_organization(socket, :edit, org_params) do
    case Orgs.update_organization(socket.assigns.organization, org_params) do
      {:ok, organization} ->
        notify_parent({:saved, organization})

        {:noreply,
         socket
         |> put_flash(:info, "Organization updated successfully.")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:org_form, to_form(changeset, as: :org_form))}
    end
  end

  defp save_organization(socket, :new, org_params) do
    case Orgs.create_organization(org_params) do
      {:ok, organization} ->
        notify_parent({:saved, organization})

        {:noreply,
         socket
         |> put_flash(:info, "Organization created successfully.")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:org_form, to_form(changeset, as: :org_form))}
    end
  end

  defp notify_parent(msg) do
    send(self(), {__MODULE__, msg})
  end
end
