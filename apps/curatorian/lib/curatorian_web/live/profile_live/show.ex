defmodule CuratorianWeb.ProfileLive.Show do
  use CuratorianWeb, :live_view

  alias Voile.Schema.Accounts
  alias Curatorian.{Accounts, Blogs}

  import CuratorianWeb.Utils.Basic.FormatIndonesiaTime

  # Helper functions
  def trim_description(description, number \\ 200) do
    description
    |> String.trim_trailing()
    |> HtmlSanitizeEx.strip_tags()
    |> String.slice(0..number)
    |> Kernel.<>("...")
  end

  def convert_time_zone_to_indonesia(time) do
    time
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!("Asia/Jakarta")
    |> format_indonesian_date()
  end

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    user =
      Accounts.get_user_by_email(username) ||
        Accounts.search_users(%{"query" => username}) |> List.first()

    case user do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "User not found")
         |> redirect(to: ~p"/")}

      %Voile.Schema.Accounts.User{} ->
        if user.confirmed_at != nil do
          current_user = socket.assigns.current_scope.user

          following =
            if current_user, do: Accounts.is_following?(current_user.id, user.id), else: false

          followers_count = Accounts.count_followers(user.id)
          following_count = Accounts.count_following(user.id)

          blogs = Blogs.list_blogs_by_user(user.id)
          posts = Blogs.list_posts_by_user(user.id)

          {:ok,
           socket
           |> assign(:user, user)
           |> assign(:blogs, blogs)
           |> assign(:posts, posts)
           |> assign(:following, following)
           |> assign(:followers_count, followers_count)
           |> assign(:following_count, following_count)
           |> assign(:active_tab, "blogs")
           |> assign(:page_title, "#{user.username}'s Profile")}
        else
          {:ok,
           socket
           |> put_flash(:error, "User not found")
           |> redirect(to: ~p"/")}
        end
    end
  end

  @impl true
  def handle_event("follow", %{"user-id" => target_user_id}, socket) do
    current_user = socket.assigns.current_scope.user

    case Accounts.follow_user(%{follower_id: current_user.id, followed_id: target_user_id}) do
      {:ok, _follow} ->
        {:noreply,
         socket
         |> assign(:following, true)
         |> assign(:followers_count, socket.assigns.followers_count + 1)
         |> put_flash(:info, "You are now following #{socket.assigns.user.username}")}

      {:error, :cannot_follow_self} ->
        {:noreply, put_flash(socket, :error, "You cannot follow yourself")}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to follow user: #{inspect(changeset)}")}
    end
  end

  @impl true
  def handle_event("unfollow", %{"user-id" => target_user_id}, socket) do
    current_user = socket.assigns.current_scope.user

    case Accounts.unfollow_user(current_user.id, target_user_id) do
      {:ok, _follow} ->
        {:noreply,
         socket
         |> assign(:following, false)
         |> assign(:followers_count, socket.assigns.followers_count - 1)
         |> put_flash(:info, "You unfollowed #{socket.assigns.user.username}")}

      {:error, :not_following} ->
        {:noreply, put_flash(socket, :error, "You are not following this user")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to unfollow user")}
    end
  end

  @impl true
  def handle_params(%{"tab" => tab}, _url, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
