defmodule CuratorianWeb.UserLive.Settings do
  use CuratorianWeb, :live_view_dashboard

  alias Curatorian.Repo
  alias Curatorian.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="w-full px-5 py-8">
      <div class="w-full">
        <.header>
          <h1 class="text-3xl font-bold text-gray-900 dark:text-white">Pengaturan Profil</h1>

          <:subtitle>
            <p class="text-gray-600 dark:text-gray-400 mt-2">
              Kelola informasi profil dan keamanan akun Anda
            </p>
          </:subtitle>
        </.header>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Sidebar Profile Card -->
          <div class="lg:col-span-1">
            <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 sticky top-6">
              <!-- Profile Image Section -->
              <div class="text-center mb-6">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Foto Profil</h3>

                <%= if length(@uploads.avatar.entries) === 0 do %>
                  <div id="user-image" class="mb-4">
                    <%= if @current_user_profile.user_image do %>
                      <img
                        phx-track-static
                        src={@current_user_profile.user_image}
                        class="w-32 h-32 rounded-full mx-auto object-cover border-4 border-violet-200 dark:border-violet-600 shadow-lg"
                        alt="User Image"
                      />
                    <% else %>
                      <img
                        phx-track-static
                        src={~p"/images/default.png"}
                        class="w-32 h-32 rounded-full mx-auto object-cover border-4 border-gray-200 dark:border-gray-600 shadow-lg"
                        alt="User Image"
                      />
                    <% end %>
                  </div>
                <% end %>

                <div phx-drop-target={@uploads.avatar.ref}>
                  <form
                    id="upload-form"
                    phx-submit="upload_image"
                    phx-change="validate"
                    class="hidden"
                  >
                    <.live_file_input upload={@uploads.avatar} />
                    <.button type="submit" id="submit-image">Upload</.button>
                  </form>

                  <%= if length(@uploads.avatar.entries) === 0 do %>
                    <.button
                      type="click"
                      class="w-full btn-primary"
                      phx-click={JS.dispatch("click", to: "##{@uploads.avatar.ref}")}
                    >
                      <.icon name="hero-camera" class="w-4 h-4 mr-2" /> Ganti Foto
                    </.button>
                  <% end %>

                  <article
                    :for={entry <- @uploads.avatar.entries}
                    class="upload-entry mt-4"
                  >
                    <figure>
                      <.live_img_preview
                        entry={entry}
                        class="w-32 h-32 rounded-full mx-auto object-cover border-4 border-violet-300 dark:border-violet-500"
                      />
                    </figure>

                    <div class="flex gap-2 mt-4">
                      <.button
                        type="button"
                        phx-click="cancel-upload"
                        phx-value-ref={entry.ref}
                        aria-label="cancel"
                        class="flex-1 btn-cancel"
                      >
                        Batal
                      </.button>
                      <.button type="button" phx-click="upload_image" class="flex-1 btn-confirm">
                        Simpan
                      </.button>
                    </div>

                    <p
                      :for={err <- upload_errors(@uploads.avatar, entry)}
                      class="alert alert-danger mt-2"
                    >
                      {error_to_string(err)}
                    </p>
                  </article>

                  <p :for={err <- upload_errors(@uploads.avatar)} class="alert alert-danger">
                    {error_to_string(err)}
                  </p>
                </div>
              </div>
              <!-- Profile Info -->
              <div class="border-t border-gray-200 dark:border-gray-700 pt-6 space-y-4">
                <div class="flex items-start gap-3">
                  <.icon name="hero-user" class="w-5 h-5 text-gray-500 dark:text-gray-400 mt-0.5" />
                  <div class="flex-1 min-w-0">
                    <p class="text-xs text-gray-500 dark:text-gray-400 mb-1">Nama Lengkap</p>

                    <p class="text-sm font-medium text-gray-900 dark:text-white truncate">
                      {if @user.profile != nil, do: @user.profile.fullname, else: "Belum diisi"}
                    </p>
                  </div>
                </div>

                <div class="flex items-start gap-3">
                  <.icon
                    name="hero-envelope"
                    class="w-5 h-5 text-gray-500 dark:text-gray-400 mt-0.5"
                  />
                  <div class="flex-1 min-w-0">
                    <p class="text-xs text-gray-500 dark:text-gray-400 mb-1">Email</p>

                    <a
                      href={"mailto:#{@user.email}"}
                      class="text-sm text-violet-600 dark:text-violet-400 truncate block hover:underline"
                    >
                      {@user.email}
                    </a>
                  </div>
                </div>

                <div class="flex items-start gap-3">
                  <.icon
                    name="hero-at-symbol"
                    class="w-5 h-5 text-gray-500 dark:text-gray-400 mt-0.5"
                  />
                  <div class="flex-1 min-w-0">
                    <p class="text-xs text-gray-500 dark:text-gray-400 mb-1">Username</p>

                    <p class="text-sm font-medium text-gray-900 dark:text-white truncate">
                      @{@user.username}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <!-- Main Content Area -->
          <div class="lg:col-span-2 space-y-6">
            <!-- Biodata Section -->
            <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
              <div class="flex items-center gap-3 mb-6 pb-4 border-b border-gray-200 dark:border-gray-700">
                <.icon
                  name="hero-identification"
                  class="w-6 h-6 text-violet-600 dark:text-violet-400"
                />
                <h2 class="text-xl font-bold text-gray-900 dark:text-white">Biodata</h2>
              </div>

              <.form
                for={@update_profile_form}
                phx-change="validate_profile"
                phx-submit="update_profile"
              >
                <div class="space-y-4">
                  <.input
                    field={@update_profile_form[:fullname]}
                    value={@current_user_profile.fullname}
                    label="Nama Lengkap"
                    type="text"
                    id="fullname"
                    placeholder="Masukkan nama lengkap Anda"
                  />
                  <.input
                    field={@update_profile_form[:bio]}
                    value={@current_user_profile.bio}
                    label="Bio"
                    type="textarea"
                    id="bio"
                    placeholder="Ceritakan tentang diri Anda"
                  />
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <.input
                      field={@update_profile_form[:job_title]}
                      value={@current_user_profile.job_title}
                      label="Pekerjaan"
                      type="text"
                      id="job-title"
                      placeholder="Posisi/Jabatan"
                    />
                    <.input
                      field={@update_profile_form[:company]}
                      value={@current_user_profile.company}
                      label="Perusahaan / Lembaga"
                      type="text"
                      id="company"
                      placeholder="Nama perusahaan"
                    />
                  </div>

                  <.input
                    field={@update_profile_form[:location]}
                    value={@current_user_profile.location}
                    label="Alamat / Lokasi"
                    type="textarea"
                    id="location"
                    placeholder="Kota, Negara"
                  />
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
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
                  </div>
                </div>
                <!-- Education Section within form -->
                <div class="mt-8 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <div class="flex items-center justify-between mb-4">
                    <div class="flex items-center gap-3">
                      <.icon
                        name="hero-academic-cap"
                        class="w-6 h-6 text-violet-600 dark:text-violet-400"
                      />
                      <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
                        Riwayat Pendidikan
                      </h3>
                    </div>

                    <%= if @show_add_education do %>
                      <button type="button" class="btn-primary text-sm" phx-click="add_education">
                        <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Tambah
                      </button>
                    <% end %>
                  </div>

                  <div class="space-y-4">
                    <.inputs_for :let={edu} field={@update_profile_form[:educations]}>
                      <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4 border border-gray-200 dark:border-gray-600">
                        <div class="flex items-center justify-between mb-3">
                          <p class="text-sm font-semibold text-violet-600 dark:text-violet-400">
                            Pendidikan #{edu.index + 1}
                          </p>

                          <%= if edu.data.id do %>
                            <button
                              type="button"
                              class="btn-cancel text-xs px-2 py-1"
                              phx-click="delete_education"
                              phx-value-education-id={edu.data.id}
                            >
                              <.icon name="hero-trash" class="w-4 h-4" />
                            </button>
                          <% else %>
                            <button
                              type="button"
                              class="btn-warning text-xs px-2 py-1"
                              phx-click="delete_unsaved_education"
                              phx-value-index={edu.index}
                            >
                              <.icon name="hero-trash" class="w-4 h-4" />
                            </button>
                          <% end %>
                        </div>

                        <.input field={edu[:id] || ""} type="hidden" id={"education-id-#{edu.index}"} />
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                          <.input
                            field={edu[:school]}
                            label="Sekolah / Universitas"
                            type="text"
                            id={"school-#{edu.index}"}
                            placeholder="Nama institusi"
                          />
                          <.input
                            field={edu[:degree]}
                            label="Jenjang"
                            type="select"
                            id={"degree-#{edu.index}"}
                            options={[
                              {"Pilih Jenjang", ""},
                              {"Sekolah", "Sekolah"},
                              {"Diploma", "Diploma"},
                              {"Sarjana", "Sarjana"},
                              {"Magister", "Magister"},
                              {"Doktor", "Doktor"}
                            ]}
                          />
                          <.input
                            field={edu[:field_of_study]}
                            label="Jurusan / Program Studi"
                            type="text"
                            id={"field-of-study-#{edu.index}"}
                            placeholder="Nama jurusan"
                          />
                          <.input
                            field={edu[:graduation_year]}
                            label="Tahun Lulus"
                            type="number"
                            id={"graduation-year-#{edu.index}"}
                            placeholder="2020"
                          />
                        </div>
                      </div>
                    </.inputs_for>
                  </div>
                </div>
                <!-- Social Media Section within form -->
                <div class="mt-8 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <div class="flex items-center gap-3 mb-4">
                    <.icon name="hero-share" class="w-6 h-6 text-violet-600 dark:text-violet-400" />
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Media Sosial</h3>
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <.input
                      field={@update_profile_form[:twitter]}
                      value={@current_user_profile.social_media["twitter"]}
                      label="Twitter"
                      type="text"
                      id="twitter"
                      placeholder="@username"
                    />
                    <.input
                      field={@update_profile_form[:facebook]}
                      value={@current_user_profile.social_media["facebook"]}
                      label="Facebook"
                      type="text"
                      id="facebook"
                      placeholder="profile.url"
                    />
                    <.input
                      field={@update_profile_form[:linkedin]}
                      value={@current_user_profile.social_media["linkedin"]}
                      label="LinkedIn"
                      type="text"
                      id="linkedin"
                      placeholder="linkedin.com/in/username"
                    />
                    <.input
                      field={@update_profile_form[:instagram]}
                      value={@current_user_profile.social_media["instagram"]}
                      label="Instagram"
                      type="text"
                      id="instagram"
                      placeholder="@username"
                    />
                    <.input
                      field={@update_profile_form[:website]}
                      value={@current_user_profile.social_media["website"]}
                      label="Website"
                      type="text"
                      id="website"
                      placeholder="https://yourwebsite.com"
                      class="md:col-span-2"
                    />
                  </div>
                </div>

                <div class="flex justify-end pt-6 mt-6 border-t border-gray-200 dark:border-gray-700">
                  <.button phx-disable-with="Menyimpan..." class="btn-primary px-8">
                    <.icon name="hero-check" class="w-4 h-4 mr-2" /> Simpan Perubahan
                  </.button>
                </div>
              </.form>
            </div>
            <!-- Password Section -->
            <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
              <div class="flex items-center gap-3 mb-6 pb-4 border-b border-gray-200 dark:border-gray-700">
                <.icon name="hero-lock-closed" class="w-6 h-6 text-violet-600 dark:text-violet-400" />
                <h2 class="text-xl font-bold text-gray-900 dark:text-white">Keamanan Akun</h2>
              </div>

              <.form
                for={@password_form}
                id="password_form"
                action={~p"/users/update-password"}
                method="post"
                phx-change="validate_password"
                phx-submit="update_password"
                phx-trigger-action={@trigger_submit}
              >
                <input
                  name={@password_form[:email].name}
                  type="hidden"
                  id="hidden_user_email"
                  autocomplete="username"
                  value={@current_email}
                />
                <div class="space-y-4">
                  <.input
                    field={@password_form[:password]}
                    type="password"
                    label="Kata Sandi Baru"
                    autocomplete="new-password"
                    placeholder="Minimal 8 karakter"
                    required
                  />
                  <.input
                    field={@password_form[:password_confirmation]}
                    type="password"
                    label="Konfirmasi Kata Sandi Baru"
                    autocomplete="new-password"
                    placeholder="Ulangi kata sandi baru"
                  />
                </div>

                <div class="flex justify-end pt-6 mt-6 border-t border-gray-200 dark:border-gray-700">
                  <.button variant="primary" phx-disable-with="Menyimpan..." class="btn-primary px-8">
                    <.icon name="hero-shield-check" class="w-4 h-4 mr-2" /> Ubah Kata Sandi
                  </.button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user |> Repo.preload(:profile)
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
      |> assign(:trigger_submit, false)
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
    changeset = Accounts.change_user_profile(socket.assigns.current_scope.user_profile)

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
    user = socket.assigns.current_scope.user

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
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_profile", %{"user_profile" => params}, socket) do
    changeset =
      socket.assigns.current_scope.user.profile
      |> Accounts.change_user_profile(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, update_profile_form: to_form(changeset))}
  end

  @impl Phoenix.LiveView
  def handle_event("update_profile", %{"user_profile" => params}, socket) do
    user = socket.assigns.current_scope.user

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

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end

  defp error_to_string(:too_large), do: "Too large"

  defp error_to_string(:too_many_files), do: "You have selected too many files"

  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
