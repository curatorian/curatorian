defmodule CuratorianWeb.UserSettingsLive do
  use CuratorianWeb, :live_view

  alias Curatorian.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
    </.header>

    <div class="space-y-12">
      <div>
        <div>
          <%= if @current_user_profile.user_image do %>
            <img
              src={@current_user_profile.user_image}
              class="w-24 h-24 cursor-pointer"
              alt="User Image"
            />
          <% else %>
            <img src={~p"/images/default.png"} class="w-24 h-24 cursor-pointer" alt="User Image" />
          <% end %>
        </div>
        
        <div class="container" phx-drop-target={@uploads.avatar.ref}>
          <form id="upload-form" phx-submit="upload_image" phx-change="validate">
            <.live_file_input upload={@uploads.avatar} />
            <button class="bg-blue-500 py-2 px-4 text-white rounded" type="submit">Upload</button>
          </form>
        </div>
        
        <div phx-drop-target={@uploads.avatar.ref}>
          <%!-- render each avatar entry --%>
          <article :for={entry <- @uploads.avatar.entries} class="upload-entry">
            <figure>
              <.live_img_preview entry={entry} />
              <figcaption>{entry.client_name}</figcaption>
            </figure>
             <%!-- entry.progress will update automatically for in-flight entries --%>
            <progress value={entry.progress} max="100">{entry.progress}%</progress>
            <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
            <button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              aria-label="cancel"
            >
              &times;
            </button>
             <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
            <p :for={err <- upload_errors(@uploads.avatar, entry)} class="alert alert-danger">
              {error_to_string(err)}
            </p>
          </article>
           <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
          <p :for={err <- upload_errors(@uploads.avatar)} class="alert alert-danger">
            {error_to_string(err)}
          </p>
        </div>
      </div>
      
      <div class="tabs">
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
      </div>
      
      <%= case @current_tab do %>
        <% :tab1 -> %>
          <div>
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
                <.button>Update Profile</.button>
              </:actions>
            </.simple_form>
          </div>
        <% :tab2 -> %>
          <div>
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
          </div>
        <% :tab3 -> %>
          <div>
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
              <.input field={@password_form[:password]} type="password" label="New password" required />
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
          </div>
      <% end %>
    </div>
    """
  end

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
      |> allow_upload(:avatar, accept: ~w(.jpg .jpeg), max_entries: 2)

    {:ok, socket}
  end

  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, current_tab: String.to_existing_atom(tab))}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("upload_image", %{"avatar" => _upload}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
        dest =
          Path.join(
            Application.app_dir(:my_app, "priv/static/uploads/user_image"),
            Path.basename(path)
          )

        File.cp!(path, dest)
        {:ok, ~p"/uploads/user_image/#{Path.basename(dest)}"}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

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

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

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
