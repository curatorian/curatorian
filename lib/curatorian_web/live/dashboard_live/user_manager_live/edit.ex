defmodule CuratorianWeb.DashboardLive.UserManagerLive.Edit do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <.header>
      Edit User Profile
    </.header>

    <.back navigate={"/dashboard/user_manager/#{@user.username}"}>Kembali</.back>

    <section>
      <.simple_form for={@form} phx-submit="save">
        <.input field={@form[:fullname]} label="Full Name" type="text" />
        <.input field={@form[:bio]} label="Bio" type="textarea" />
        <.input field={@form[:job_title]} label="Pekerjaan" type="text" id="phone-number" />
        <.input field={@form[:company]} label="Perusahaan / Lembaga" type="text" id="company" />
        <.input field={@form[:location]} label="Alamat / Lokasi" type="textarea" id="location" />
        <.input field={@form[:birthday]} label="Tanggal Lahir" type="date" id="birthday" />
        <.input
          field={@form[:gender]}
          label="Jenis Kelamin"
          type="select"
          options={[
            {"Pilih Jenis Kelamin", nil},
            {"Laki-laki", "laki-laki"},
            {"Perempuan", "perempuan"}
          ]}
          id="gender"
        />
        <.input
          field={@form[:user_role]}
          label="Role"
          type="select"
          options={[{"Curator", "curator"}, {"Manager", "manager"}]}
        />
        <.button>Save Changes</.button>
      </.simple_form>
    </section>
    """
  end

  def mount(params, _session, socket) do
    user = Accounts.get_user_profile_by_username(params["username"])
    profile = Accounts.get_user_profile_by_user_id(user.id)

    merged_params = %{
      user_role: user.user_role,
      fullname: profile.fullname,
      bio: profile.bio
    }

    types = %{user_role: :string, fullname: :string, bio: :string}

    changeset =
      {%{}, types}
      |> Ecto.Changeset.cast(merged_params, Map.keys(types))

    socket =
      socket
      |> assign(:user, user)
      |> assign(:profile, profile)
      |> assign(:form, to_form(changeset, as: :form))
      |> assign(:page_title, "Edit user profile for #{profile.fullname}")

    {:ok, socket}
  end

  def handle_event("save", %{"form" => form_params}, socket) do
    user_params = %{"user_role" => form_params["user_role"]}

    profile_params = %{
      "fullname" => form_params["fullname"],
      "bio" => form_params["bio"]
    }

    user = socket.assigns.user
    profile = socket.assigns.profile

    case Accounts.update_user_and_profile(user, user_params, profile, profile_params) do
      {:ok, %{user: updated_user, profile: updated_profile}} ->
        merged_params = %{
          user_role: updated_user.user_role,
          fullname: updated_profile.fullname,
          bio: updated_profile.bio
        }

        changeset =
          {%{}, %{user_role: :string, fullname: :string, bio: :string}}
          |> Ecto.Changeset.cast(merged_params, [:user_role, :fullname, :bio])

        {:noreply,
         socket
         |> put_flash(:info, "User and profile updated")
         |> assign(:user, updated_user)
         |> assign(:profile, updated_profile)
         |> assign(:form, to_form(changeset, as: :form))}

      {:error, :user, _changeset, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update user")}

      {:error, :profile, _changeset, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update profile")}
    end
  end
end
