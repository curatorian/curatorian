defmodule CuratorianWeb.UserLive.Settings do
  use CuratorianWeb, :live_view_dashboard

  alias Voile.Schema.Accounts

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
                      {@current_user_profile.fullname || "Belum diisi"}
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
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <.input
                      field={@update_profile_form[:organization]}
                      value={@current_user_profile.organization}
                      label="Organisasi"
                      type="text"
                      id="organization"
                      placeholder="Nama organisasi"
                    />
                    <.input
                      field={@update_profile_form[:department]}
                      value={@current_user_profile.department}
                      label="Departemen"
                      type="text"
                      id="department"
                      placeholder="Departemen"
                    />
                  </div>

                  <.input
                    field={@update_profile_form[:position]}
                    value={@current_user_profile.position}
                    label="Posisi"
                    type="text"
                    id="position"
                    placeholder="Posisi/Jabatan"
                  />
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <.input
                      field={@update_profile_form[:phone_number]}
                      value={@current_user_profile.phone_number}
                      label="Nomor Telepon"
                      type="text"
                      id="phone_number"
                      placeholder="Nomor telepon"
                    />
                    <.input
                      field={@update_profile_form[:birth_date]}
                      value={@current_user_profile.birth_date}
                      label="Tanggal Lahir"
                      type="date"
                      id="birth_date"
                    />
                  </div>
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
                
    <!-- Social Media Section within form -->
                <div class="mt-8 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <div class="flex items-center gap-3 mb-4">
                    <.icon name="hero-share" class="w-6 h-6 text-violet-600 dark:text-violet-400" />
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Media Sosial</h3>
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <.input
                      field={@update_profile_form[:twitter]}
                      value={@current_user_profile.twitter}
                      label="Twitter"
                      type="text"
                      id="twitter"
                      placeholder="@username"
                    />
                    <.input
                      field={@update_profile_form[:facebook]}
                      value={@current_user_profile.facebook}
                      label="Facebook"
                      type="text"
                      id="facebook"
                      placeholder="profile.url"
                    />
                    <.input
                      field={@update_profile_form[:linkedin]}
                      value={@current_user_profile.linkedin}
                      label="LinkedIn"
                      type="text"
                      id="linkedin"
                      placeholder="linkedin.com/in/username"
                    />
                    <.input
                      field={@update_profile_form[:instagram]}
                      value={@current_user_profile.instagram}
                      label="Instagram"
                      type="text"
                      id="instagram"
                      placeholder="@username"
                    />
                    <.input
                      field={@update_profile_form[:website]}
                      value={@current_user_profile.website}
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
    user = socket.assigns.current_scope.user

    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    profile_changeset = Accounts.change_user(user)

    socket =
      socket
      |> assign(:user, user)
      |> assign(:current_email, user.email)
      |> assign(:current_password, nil)
      |> assign(:current_tab, :tab1)
      |> assign(:current_user_profile, user)
      |> assign(:educations, [])
      |> assign(:email_form_current_password, nil)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:update_profile_form, to_form(profile_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:show_add_education, false)
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
    # Education not supported in Voile
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_unsaved_education", _params, socket) do
    # Education not supported in Voile
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_education", _params, socket) do
    # Education not supported in Voile
    {:noreply, socket}
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

        case Accounts.update_profile_user(user, %{user_image: image_path}) do
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
      socket.assigns.current_scope.user
      |> Accounts.change_user(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, update_profile_form: to_form(changeset))}
  end

  @impl Phoenix.LiveView
  def handle_event("update_profile", %{"user_profile" => params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_profile_user(user, params) do
      {:ok, updated_user} ->
        info = "#{updated_user.fullname}'s updated successfully."
        profile_form = updated_user |> Accounts.change_user() |> to_form()

        {:noreply,
         socket
         |> put_flash(:info, info)
         |> assign(update_profile_form: profile_form)
         |> assign(current_user_profile: updated_user)}

      {:error, changeset} ->
        dbg(changeset)
        {:noreply, assign(socket, update_profile_form: to_form(changeset))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params)
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
