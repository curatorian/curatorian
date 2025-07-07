defmodule CuratorianWeb.DashboardLive.OrgsLive.OrganizationForm do
  use CuratorianWeb, :live_component

  alias Curatorian.Orgs
  # alias Curatorian.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="organization-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <div class="space-y-3">
          <label class="block text-sm font-medium">Cover Image</label>
          <%= if @organization.image_cover && Enum.empty?(@uploads.image_cover.entries) do %>
            <div class="mb-2 flex flex-col gap-2">
              <img
                src={@organization.image_cover}
                alt="Cover image"
                class="rounded w-full h-full max-h-[480px] object-cover"
              />
              <button
                type="button"
                class="btn-cancel text-sm text-red-600"
                phx-click="remove-image"
                phx-value-field="image_cover"
                phx-target={@myself}
              >
                Remove image
              </button>
            </div>
          <% else %>
            <.live_file_input upload={@uploads.image_cover} />
            <%= if Enum.any?(@uploads.image_cover.entries) do %>
              <%= for entry <- @uploads.image_cover.entries do %>
                <div class="mt-2">
                  <.live_img_preview
                    entry={entry}
                    class="rounded w-full h-full max-h-[480px] object-cover"
                  />
                </div>
                 <progress value={entry.progress} max="100">{entry.progress}%</progress>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-field="image_cover"
                  phx-value-ref={entry.ref}
                  phx-target={@myself}
                  class="btn-warning text-sm text-red-600"
                >
                  Cancel
                </button>
              <% end %>
            <% end %>
          <% end %>
        </div>
        
        <div class="grid items-center justify-center grid-cols-1 md:grid-cols-5 gap-4">
          <div class="space-y-3">
            <label class="block text-sm font-medium">Profile Image</label>
            <%= if @organization.image_logo && Enum.empty?(@uploads.image_logo.entries) do %>
              <div class="mb-2 flex flex-col gap-2">
                <img
                  src={@organization.image_logo}
                  alt="Profile image"
                  class="w-64 h-64 object-cover rounded"
                />
                <button
                  type="button"
                  class="btn-cancel text-sm text-red-600"
                  phx-click="remove-image"
                  phx-value-field="image_logo"
                  phx-target={@myself}
                >
                  Remove image
                </button>
              </div>
            <% else %>
              <.live_file_input upload={@uploads.image_logo} />
              <%= if Enum.any?(@uploads.image_logo.entries) do %>
                <%= for entry <- @uploads.image_logo.entries do %>
                  <div class="mt-2">
                    <.live_img_preview entry={entry} width="100" />
                  </div>
                   <progress value={entry.progress} max="100">{entry.progress}%</progress>
                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-field="image_logo"
                    phx-value-ref={entry.ref}
                    phx-target={@myself}
                    class="btn-warning text-sm text-red-600"
                  >
                    Cancel
                  </button>
                <% end %>
              <% end %>
            <% end %>
          </div>
          
          <div class="col-span-4 flex flex-col justify-evenly h-full">
            <.input field={@form[:name]} type="text" label="Name" />
            <.input field={@form[:slug]} type="text" label="Slug" phx-hook="Slugify" id="slug" />
            <.input
              field={@form[:status]}
              type="select"
              label="Status"
              options={[
                {"Draft", "draft"},
                {"Pending", "pending"},
                {"Approved", "approved"},
                {"Archived", "archived"}
              ]}
              prompt="Select status of organization"
              disabled={@current_user.user_role != "manager"}
            />
            <.input
              field={@form[:type]}
              type="select"
              label="Type"
              options={[
                {"Company", "company"},
                {"Institution", "institution"},
                {"Community", "community"},
                {"Non-profit", "non_profit"}
              ]}
              prompt="Select type of organization"
            />
          </div>
        </div>
         <.input field={@form[:description]} type="textarea" label="Description" />
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
     |> assign(:action, action)
     |> allow_upload(:image_logo, accept: ~w(.jpg .jpeg .png), max_entries: 1)
     |> allow_upload(:image_cover, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
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

  def handle_event("cancel-upload", %{"ref" => ref, "field" => field}, socket) do
    {:noreply, Phoenix.LiveView.cancel_upload(socket, String.to_existing_atom(field), ref)}
  end

  def handle_event("remove-image", %{"field" => field}, socket) do
    organization = socket.assigns.organization
    field_atom = String.to_existing_atom(field)

    # Update the organization with nil value for the specified field
    {:ok, updated_organization} =
      case field_atom do
        :image_logo -> Orgs.update_organization(organization, %{"image_logo" => nil})
        :image_cover -> Orgs.update_organization(organization, %{"image_cover" => nil})
      end

    {:noreply,
     socket
     |> assign(:organization, updated_organization)
     |> put_flash(:info, "#{String.capitalize(field)} removed successfully")}
  end

  def handle_event("save", %{"organization" => organization_params}, socket) do
    # Process uploads
    organization_params = process_uploads(socket, organization_params)

    save_organization(socket, socket.assigns.action, organization_params)
  end

  defp process_uploads(socket, organization_params) do
    image_logo_path = handle_upload(socket, :image_logo)
    image_cover_path = handle_upload(socket, :image_cover)

    organization_params
    |> maybe_put_image_path("image_logo", image_logo_path)
    |> maybe_put_image_path("image_cover", image_cover_path)
  end

  defp maybe_put_image_path(params, _key, nil), do: params
  defp maybe_put_image_path(params, key, path), do: Map.put(params, key, path)

  defp handle_upload(socket, upload_field) do
    case uploaded_entries(socket, upload_field) do
      {[entry], _} ->
        consume_uploaded_entry(socket, entry, fn %{path: path} ->
          dest = Path.join(["priv", "static", "uploads", "organizations", Path.basename(path)])
          File.mkdir_p!(Path.dirname(dest))
          File.cp!(path, dest)
          {:ok, "/uploads/organizations/#{Path.basename(dest)}"}
        end)

      _ ->
        nil
    end
  end

  defp save_organization(socket, :edit, organization_params) do
    case Orgs.update_organization(socket.assigns.organization, organization_params) do
      {:ok, organization} ->
        notify_parent({:saved, organization})

        {:noreply,
         socket
         |> put_flash(:info, "Organization updated successfully")
         |> push_navigate(to: ~p"/dashboard/orgs/#{organization.slug}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_organization(socket, :new, organization_params) do
    organization_params =
      organization_params
      |> Map.put("owner_id", socket.assigns.current_user.id)
      |> Map.put("user_id", socket.assigns.current_user.id)

    dbg(organization_params)

    case Orgs.create_organization(socket.assigns.current_user, organization_params) do
      {:ok, organization} ->
        notify_parent({:saved, organization})

        {:noreply,
         socket
         |> put_flash(:info, "Organization created successfully")
         |> push_navigate(to: ~p"/dashboard/orgs/#{organization.slug}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        dbg(changeset)
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
