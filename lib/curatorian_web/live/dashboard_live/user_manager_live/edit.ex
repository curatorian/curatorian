defmodule CuratorianWeb.DashboardLive.UserManagerLive.Edit do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Accounts
  alias Curatorian.Authorization

  def render(assigns) do
    ~H"""
    <.header>
      Edit User Profile
      <:subtitle>Manage user information and permissions</:subtitle>
    </.header>

    <.button navigate={~p"/dashboard/user_manager/#{@user.username}"} class="mt-4">
      <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" /> Back to Profile
    </.button>
    <div class="mt-6 bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <.form for={@form} phx-submit="save" phx-change="validate">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <%!-- Personal Information --%>
          <div class="col-span-2">
            <h3 class="text-lg font-semibold mb-4 dark:text-gray-200">Personal Information</h3>
          </div>
           <.input field={@form[:fullname]} label="Full Name" type="text" required />
          <.input field={@form[:email]} label="Email" type="email" required />
          <.input field={@form[:username]} label="Username" type="text" required disabled />
          <.input field={@form[:phone_number]} label="Phone Number" type="text" />
          <.input field={@form[:birthday]} label="Birthday" type="date" />
          <.input
            field={@form[:gender]}
            label="Gender"
            type="select"
            options={[
              {"Select Gender", ""},
              {"Male", "laki-laki"},
              {"Female", "perempuan"}
            ]}
          /> <%!-- Professional Information --%>
          <div class="col-span-2 mt-4">
            <h3 class="text-lg font-semibold mb-4 dark:text-gray-200">Professional Information</h3>
          </div>
           <.input field={@form[:job_title]} label="Job Title" type="text" />
          <.input field={@form[:company]} label="Company/Organization" type="text" />
          <div class="col-span-2">
            <.input field={@form[:location]} label="Location" type="textarea" rows="2" />
          </div>
          
          <div class="col-span-2">
            <.input field={@form[:bio]} label="Bio" type="textarea" rows="4" />
          </div>
           <%!-- Role & Permissions --%>
          <%= if @can_manage_roles do %>
            <div class="col-span-2 mt-4">
              <h3 class="text-lg font-semibold mb-4 dark:text-gray-200">Role & Permissions</h3>
            </div>
            
            <.input
              field={@form[:role_id]}
              label="Role"
              type="select"
              options={@role_options}
              prompt="Select a role"
            />
            <div class="col-span-2">
              <label class="block text-sm font-medium mb-2 dark:text-gray-200">Account Status</label>
              <div class="flex items-center gap-4">
                <label class="inline-flex items-center">
                  <input
                    type="checkbox"
                    name="form[is_verified]"
                    value="true"
                    checked={@form[:is_verified].value}
                    class="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50 dark:bg-gray-700 dark:border-gray-600"
                  /> <span class="ml-2 text-sm dark:text-gray-300">Verified</span>
                </label>
              </div>
            </div>
          <% end %>
        </div>
        
        <div class="mt-6 flex items-center justify-between">
          <.button type="submit" phx-disable-with="Saving...">
            <.icon name="hero-check" class="w-4 h-4 mr-2" /> Save Changes
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  def mount(params, _session, socket) do
    user = Accounts.get_user_profile_by_username(params["username"])
    profile = Accounts.get_user_profile_by_user_id(user.id)

    # Check if current user can manage roles
    current_user = socket.assigns.current_scope.user

    can_manage_roles =
      Authorization.is_super_admin?(current_user) || Authorization.is_manager?(current_user)

    # Get available roles for dropdown
    role_options =
      if can_manage_roles do
        Authorization.list_roles()
        |> Enum.map(fn role -> {role.name, role.id} end)
      else
        []
      end

    merged_params = %{
      fullname: profile.fullname,
      email: user.email,
      username: user.username,
      phone_number: profile.phone_number,
      birthday: profile.birthday,
      gender: profile.gender,
      bio: profile.bio,
      job_title: profile.job_title,
      company: profile.company,
      location: profile.location,
      role_id: user.role_id,
      is_verified: user.is_verified
    }

    changeset = Accounts.change_user(user, merged_params)

    socket =
      socket
      |> assign(:user, user)
      |> assign(:profile, profile)
      |> assign(:form, to_form(changeset))
      |> assign(:can_manage_roles, can_manage_roles)
      |> assign(:role_options, role_options)
      |> assign(:page_title, "Edit #{profile.fullname}")

    {:ok, socket}
  end

  def handle_event("validate", %{"form" => form_params} = params, socket) do
    # Get user params (which has all the form data)
    user_params = Map.get(params, "user", %{})

    # Merge form params (checkbox) with user params (all other fields)
    merged_params = Map.merge(user_params, form_params)

    changeset =
      socket.assigns.user
      |> Accounts.change_user(merged_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    # When checkbox is unchecked, there's no "form" key, just "user" key
    # Add is_verified: false explicitly
    merged_params = Map.put(user_params, "is_verified", false)

    changeset =
      socket.assigns.user
      |> Accounts.change_user(merged_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", params, socket) do
    user = socket.assigns.user
    profile = socket.assigns.profile

    # Merge both "form" and "user" params
    form_params = Map.get(params, "form", %{})
    user_params_raw = Map.get(params, "user", %{})
    all_params = Map.merge(user_params_raw, form_params)

    # Convert is_verified string to boolean
    is_verified =
      case Map.get(all_params, "is_verified") do
        "true" -> true
        true -> true
        _ -> false
      end

    # Split params for user and profile
    user_params =
      all_params
      |> Map.take(["email", "role_id"])
      |> Map.put("is_verified", is_verified)

    profile_params =
      Map.take(all_params, [
        "fullname",
        "phone_number",
        "birthday",
        "gender",
        "bio",
        "job_title",
        "company",
        "location"
      ])

    case Accounts.update_user_and_profile(user, user_params, profile, profile_params) do
      {:ok, %{user: updated_user, profile: _updated_profile}} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_navigate(to: ~p"/dashboard/user_manager/#{updated_user.username}")}

      {:error, :user, changeset, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update user")
         |> assign(:form, to_form(changeset))}

      {:error, :profile, _changeset, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update profile")}
    end
  end
end
