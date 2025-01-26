defmodule CuratorianWeb.UserSettingsLive do
  use CuratorianWeb, :live_view

  alias Curatorian.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-5">
      <.header class="text-center pt-32">
        Account Settings
        <:subtitle>Manage your account email address and password settings</:subtitle>
      </.header>
      
      <section class="flex flex-col gap-5 lg:flex-row items-center lg:items-start justify-center min-h-screen h-full">
        <div class="bg-violet-100 p-10 rounded w-full sm:max-w-80">
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
                    class="w-full btn"
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
                    class="w-full cancel-btn"
                  >
                    Batal
                  </.button>
                  
                  <.button type="button" phx-click="upload_image" class="w-full confirm-btn">
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
                <div class="w-full bg-violet-600 text-center text-white p-0 mb-2 rounded">
                  <h5>Profil</h5>
                </div>
                
                <div class="flex items-center w-full gap-2 py-2">
                  <.icon name="hero-user-solid" class="w-6 h-6 max-w-8" />
                  <p class="max-w-48">
                    {@current_user.profile.fullname}
                  </p>
                </div>
                
                <div class="flex items-center w-full gap-2 py-2">
                  <.icon name="hero-at-symbol-solid" class="w-6 h-6 max-w-8" />
                  <p class="max-w-48">
                    {@current_user.email}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <div class="w-full">
          <.simple_form for={@update_profile_form} phx-submit="update_profile">
            <.input
              field={@update_profile_form[:fullname]}
              value={@current_user_profile.fullname}
              name="fullname"
              label="Full Name"
              type="text"
              id="fullname"
            />
            <.input
              field={@update_profile_form[:bio]}
              value={@current_user_profile.bio}
              name="bio"
              label="Bio"
              type="textarea"
              id="bio"
            />
            <:actions>
              <.button class="default-btn">Update Profile</.button>
            </:actions>
          </.simple_form>
        </div>
        
        <div>
          <%!-- <div class="tabs">
            <button
              phx-click="change_tab"
              phx-value-tab="tab1"
              class={if @current_tab == :tab1, do: "active", else: ""}
            >
              Profile
            </button>

            <button
              phx-click="change_tab"
              phx-value-tab="tab2"
              class={if @current_tab == :tab2, do: "active", else: ""}
            >
              Change Email
            </button>

            <button
              phx-click="change_tab"
              phx-value-tab="tab3"
              class={if @current_tab == :tab3, do: "active", else: ""}
            >
              Update Password
            </button>
          </div> --%>
          <%= case @current_tab do %>
            <% :tab1 -> %>
              <div />
            <% :tab2 -> %>
              <%!-- <div>
                <.simple_form
                  for={@email_form}
                  id="email_form"
                  phx-submit="update_email"
                  phx-change="validate_email"
                >
                  <.input field={@email_form[:email]} type="email" label="Email" required />
                  <.input
                    field={@email_form[:current_password]}
                    name="current_password"
                    id="current_password_for_email"
                    type="password"
                    label="Current password"
                    value={@email_form_current_password}
                    required
                  />
                  <:actions>
                    <.button phx-disable-with="Changing...">Change Email</.button>
                  </:actions>
                </.simple_form>
              </div> --%>
            <% :tab3 -> %>
              <%!-- <div>
                <.simple_form
                  for={@password_form}
                  id="password_form"
                  action={~p"/users/log_in?_action=password_updated"}
                  method="post"
                  phx-change="validate_password"
                  phx-submit="update_password"
                  phx-trigger-action={@trigger_submit}
                >
                  <input
                    name={@password_form[:email].name}
                    type="hidden"
                    id="hidden_user_email"
                    value={@current_email}
                  />
                  <.input
                    field={@password_form[:password]}
                    type="password"
                    label="New password"
                    required
                  />
                  <.input
                    field={@password_form[:password_confirmation]}
                    type="password"
                    label="Confirm new password"
                  />
                  <.input
                    field={@password_form[:current_password]}
                    name="current_password"
                    type="password"
                    label="Current password"
                    id="current_password_for_password"
                    value={@current_password}
                    required
                  />
                  <:actions>
                    <.button phx-disable-with="Changing...">Change Password</.button>
                  </:actions>
                </.simple_form>
              </div> --%>
          <% end %>
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
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    profile_changeset = Accounts.change_user_profile(user_profile)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:current_password, nil)
      |> assign(:current_tab, :tab1)
      |> assign(:current_user_profile, user_profile)
      |> assign(:email_form_current_password, nil)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:update_profile_form, to_form(profile_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:uploaded_files, [])
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg),
        max_file_size: 3_000_000,
        max_entries: 1,
        auto_upload: true
      )

    dbg(socket.assigns.current_user)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, current_tab: String.to_existing_atom(tab))}
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
  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  @impl Phoenix.LiveView
  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("update_profile", params, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user_profile(user, params) do
      {:ok, profile} ->
        info = "#{profile.fullname}'s updated successfully."
        profile_form = profile |> Accounts.change_user_profile() |> to_form()

        {:noreply,
         socket
         |> put_flash(:info, info)
         |> assign(update_profile_form: profile_form)
         |> assign(current_user_profile: profile)}

      {:error, changeset} ->
        {:noreply, assign(socket, update_profile_form: to_form(changeset))}
    end
  end

  defp error_to_string(:too_large), do: "Too large"

  defp error_to_string(:too_many_files), do: "You have selected too many files"

  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
