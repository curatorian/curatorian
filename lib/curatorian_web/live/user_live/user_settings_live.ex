defmodule CuratorianWeb.UserSettingsLive do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Accounts
  # alias CuratorianWeb.Utils.Basic.ReadSocmed

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-5">
      <.header class="text-center mb-5">
        Profil Anda
        <:subtitle>Kelola Profil dan Akun anda disini.</:subtitle>
      </.header>
      
      <section class="flex flex-col gap-5 lg:flex-row items-center lg:items-start justify-center min-h-screen h-full">
        <div class="bg-white p-10 rounded-lg w-full sm:max-w-80">
          <%= if length(@uploads.avatar.entries) === 0 do %>
            <div id="user-image">
              <%= if @current_user_profile.user_image do %>
                <img
                  phx-track-static
                  src={@current_user_profile.user_image}
                  class="profile-pic"
                  alt="User Image"
                />
              <% else %>
                <img
                  phx-track-static
                  src={~p"/images/default.png"}
                  class="profile-pic"
                  alt="User Image"
                />
              <% end %>
            </div>
          <% end %>
          
          <div phx-drop-target={@uploads.avatar.ref}>
            <div class="container" phx-drop-target={@uploads.avatar.ref}>
              <form id="upload-form" phx-submit="upload_image" phx-change="validate" class="hidden">
                <.live_file_input upload={@uploads.avatar} />
                <.button type="submit" id="submit-image">Upload</.button>
              </form>
            </div>
            
            <div>
              <%= if length(@uploads.avatar.entries) === 0 do %>
                <div class="mt-3">
                  <.button
                    type="click"
                    class="w-full btn-primary"
                    phx-click={JS.dispatch("click", to: "##{@uploads.avatar.ref}")}
                  >
                    Ganti Foto
                  </.button>
                </div>
              <% end %>
               <%!-- render each avatar entry --%>
              <article :for={entry <- @uploads.avatar.entries} class="upload-entry">
                <figure>
                  <.live_img_preview entry={entry} class="profile-pic" />
                </figure>
                
                <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
                <div class="w-full flex gap-2 mt-3">
                  <.button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    aria-label="cancel"
                    class="w-full btn-cancel"
                  >
                    Batal
                  </.button>
                  
                  <.button type="button" phx-click="upload_image" class="w-full btn-confirm">
                    Simpan
                  </.button>
                </div>
                 <%!-- entry.progress will update automatically for in-flight entries --%>
                <%!-- <progress value={entry.progress} max="100">{entry.progress}%</progress> --%>
                <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
                <p :for={err <- upload_errors(@uploads.avatar, entry)} class="alert alert-danger">
                  {error_to_string(err)}
                </p>
              </article>
               <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
              <p :for={err <- upload_errors(@uploads.avatar)} class="alert alert-danger">
                {error_to_string(err)}
              </p>
               <hr class="border-t-1 border-violet-500 my-8" />
              <div class="my-5">
                <div class="w-full bg-violet-600 text-center text-white mb-2 rounded">
                  <h5>Profil</h5>
                </div>
                
                <div class="flex items-center w-full gap-2 py-2">
                  <.icon name="hero-user-solid" class="w-6 h-6 max-w-8" />
                  <p class="max-w-48">
                    {@current_user.profile.fullname}
                  </p>
                </div>
                
                <div class="flex items-center w-full gap-2 py-2">
                  <.icon name="hero-envelope-solid" class="w-6 h-6 max-w-8" />
                  <a href={"mailto:#{@current_user.email}"} class="max-w-48">
                    {@current_user.email}
                  </a>
                </div>
                
                <div class="flex items-center w-full gap-2 py-2">
                  <.icon name="hero-at-symbol-solid" class="w-6 h-6 max-w-8" />
                  <p class="max-w-48">
                    <%!-- {ReadSocmed.create_handler(@current_user_profile.social_media["twitter"])} --%> {@current_user.username}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <div class="w-full">
          <.simple_form for={@update_profile_form} as="user_profile" phx-submit="update_profile">
            <h6>Biodata</h6>
            
            <.input
              field={@update_profile_form[:fullname]}
              value={@current_user_profile.fullname}
              label="Full Name"
              type="text"
              id="fullname"
            />
            <.input
              field={@update_profile_form[:bio]}
              value={@current_user_profile.bio}
              label="Bio"
              type="textarea"
              id="bio"
            />
            <.input
              field={@update_profile_form[:job_title]}
              value={@current_user_profile.job_title}
              label="Pekerjaan"
              type="text"
              id="phone-number"
            />
            <.input
              field={@update_profile_form[:company]}
              value={@current_user_profile.company}
              label="Perusahaan / Lembaga"
              type="text"
              id="company"
            />
            <.input
              field={@update_profile_form[:location]}
              value={@current_user_profile.location}
              label="Alamat / Lokasi"
              type="textarea"
              id="location"
            />
            <.input
              field={@update_profile_form[:birthday]}
              value={@current_user_profile.birthday}
              label="Tanggal Lahir"
              type="date"
              id="birthday"
            />
            <.input
              field={@update_profile_form[:gender]}
              value={@current_user_profile.gender}
              label="Jenis Kelamin"
              type="select"
              options={[
                {"Pilih Jenis Kelamin", nil},
                {"Laki-laki", "laki-laki"},
                {"Perempuan", "perempuan"}
              ]}
              id="gender"
            />
            <h6>Pendidikan</h6>
            
            <.inputs_for :let={edu} field={@update_profile_form[:educations]}>
              <p>Pendidikan Ke-{edu.index + 1}</p>
               <.input field={edu[:id] || ""} type="hidden" id={"education-id-#{edu.index}"} />
              <div class="flex w-full items-end gap-4">
                <div class="grid grid-cols-4 gap-4 w-full -mt-8">
                  <.input
                    field={edu[:school]}
                    label="Sekolah / Universitas :"
                    type="text"
                    id={"school-#{edu.index}"}
                  />
                  <.input
                    field={edu[:degree]}
                    label="Jenjang :"
                    type="select"
                    id={"degree-#{edu.index}"}
                    options={[
                      {"Sekolah", "Sekolah"},
                      {"Diploma", "Diploma"},
                      {"Sarjana", "Sarjana"},
                      {"Magister", "Magister"},
                      {"Doktor", "Doktor"}
                    ]}
                  />
                  <.input
                    field={edu[:field_of_study]}
                    label="Jurusan / Prog. Studi :"
                    type="text"
                    id={"field-of-study-#{edu.index}"}
                  />
                  <.input
                    field={edu[:graduation_year]}
                    label="Angkatan :"
                    type="number"
                    id={"graduation-year-#{edu.index}"}
                  />
                </div>
                
                <%= if edu.data.id do %>
                  <button
                    type="button"
                    class="btn-cancel"
                    phx-click="delete_education"
                    phx-value-education-id={edu.data.id}
                  >
                    <.icon name="hero-trash-solid" class="bg-white w-4 h-4" />
                  </button>
                <% else %>
                  <!-- For unsaved entries, remove it from the changeset -->
                  <button
                    type="button"
                    class="btn-warning"
                    phx-click="delete_unsaved_education"
                    phx-value-index={edu.index}
                  >
                    <.icon name="hero-trash-solid" class="bg-white w-4 h-4" />
                  </button>
                <% end %>
              </div>
            </.inputs_for>
            
            <%= if @show_add_education do %>
              <button type="button" class="btn-primary text-xs" phx-click="add_education">
                Add Education
              </button>
            <% end %>
            
            <h6>Media Sosial</h6>
            
            <div class="grid grid-cols-3 gap-4">
              <.input
                field={@update_profile_form[:twitter]}
                value={@current_user_profile.social_media["twitter"]}
                label="Twitter"
                type="text"
                id="twitter"
              />
              <.input
                field={@update_profile_form[:facebook]}
                value={@current_user_profile.social_media["facebook"]}
                label="Facebook"
                type="text"
                id="facebook"
              />
              <.input
                field={@update_profile_form[:linkedin]}
                value={@current_user_profile.social_media["linkedin"]}
                label="LinkedIn"
                type="text"
                id="linkedin"
              />
              <.input
                field={@update_profile_form[:instagram]}
                value={@current_user_profile.social_media["instagram"]}
                label="Instagram"
                type="text"
                id="instagram"
              />
              <.input
                field={@update_profile_form[:website]}
                value={@current_user_profile.social_media["website"]}
                label="Website"
                type="text"
                id="website"
              />
            </div>
            
            <:actions>
              <.button class="">Update Profile</.button>
            </:actions>
          </.simple_form>
        </div>
      </section>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    user_profile = Accounts.get_user_profile_by_user_id(user.id)
    educations = Accounts.get_user_educations(user_profile.id)

    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    profile_changeset = Accounts.change_user_profile(user_profile)

    socket =
      socket
      |> assign(:user, user)
      |> assign(:current_email, user.email)
      |> assign(:current_password, nil)
      |> assign(:current_tab, :tab1)
      |> assign(:current_user_profile, user_profile)
      |> assign(:educations, educations)
      |> assign(:email_form_current_password, nil)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:update_profile_form, to_form(profile_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:show_add_education, true)
      |> assign(:uploaded_files, [])
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg),
        max_file_size: 3_000_000,
        max_entries: 1,
        auto_upload: true
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("add_education", _, socket) do
    changeset =
      socket.assigns.update_profile_form.data
      |> Accounts.change_user_profile()

    educations = Ecto.Changeset.get_field(changeset, :educations) || []
    new_education = %Accounts.Education{}
    updated_educations = educations ++ [new_education]

    changeset = Ecto.Changeset.put_assoc(changeset, :educations, updated_educations)

    socket =
      socket
      |> assign(update_profile_form: to_form(changeset))
      |> assign(show_add_education: false)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_unsaved_education", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)

    changeset =
      socket.assigns.update_profile_form.data
      |> Accounts.change_user_profile()

    educations = Ecto.Changeset.get_field(changeset, :educations) || []
    updated_educations = List.delete_at(educations, index)
    changeset = Ecto.Changeset.put_assoc(changeset, :educations, updated_educations)

    socket =
      socket
      |> assign(update_profile_form: to_form(changeset))
      |> assign(show_add_education: true)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_education", %{"education-id" => id}, socket) do
    changeset = Accounts.change_user_profile(socket.assigns.current_user_profile)

    updated_educations =
      Ecto.Changeset.get_field(changeset, :educations)
      |> Enum.reject(fn edu ->
        edu.id == id
      end)

    changeset = Ecto.Changeset.put_assoc(changeset, :educations, updated_educations)
    socket = assign(socket, update_profile_form: to_form(changeset))
    dbg(updated_educations)
    {:noreply, socket}

    case Accounts.delete_education(id) do
      {:ok, _} ->
        updated_profile = Accounts.get_user_profile_by_user_id(socket.assigns.user.id)
        changeset = Accounts.change_user_profile(updated_profile)
        {:noreply, assign(socket, update_profile_form: to_form(changeset))}

      {:error, _reason} ->
        # Optionally handle the error
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("upload_image", _params, socket) do
    user = socket.assigns.current_user

    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
        dest =
          Path.join(
            Application.app_dir(:curatorian, "priv/static/uploads/user_image"),
            user.id
          )

        image_path = "/uploads/user_image/#{Path.basename(dest)}"

        File.cp!(path, dest)

        case Accounts.update_user_profile(user, %{user_image: image_path}) do
          {:ok, _} ->
            {:ok, socket}

          {:error, _} ->
            {:error, socket}
        end
      end)

    socket =
      socket
      |> put_flash(:info, "Image uploaded successfully")
      |> update(:uploaded_files, &(&1 ++ uploaded_files))
      |> redirect(to: ~p"/users/settings")

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  @impl Phoenix.LiveView
  def handle_event("update_profile", %{"user_profile" => params}, socket) do
    user = socket.assigns.current_user
    IO.inspect(params, label: "🔥 Incoming Params")

    case Accounts.update_user_profile(user, params) do
      {:ok, profile} ->
        info = "#{profile.fullname}'s updated successfully."
        profile_form = profile |> Accounts.change_user_profile() |> to_form()

        {:noreply,
         socket
         |> put_flash(:info, info)
         |> assign(update_profile_form: profile_form)
         |> assign(current_user_profile: profile)
         |> assign(show_add_education: true)}

      {:error, changeset} ->
        dbg(changeset)
        {:noreply, assign(socket, update_profile_form: to_form(changeset))}

      _ ->
        {:noreply, socket}
    end
  end

  defp error_to_string(:too_large), do: "Too large"

  defp error_to_string(:too_many_files), do: "You have selected too many files"

  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
