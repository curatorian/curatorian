defmodule CuratorianWeb.Authorization do
  @moduledoc """
  Authorization helpers and plugs for LiveViews and Controllers.
  """

  import Plug.Conn, only: [halt: 1]

  alias Curatorian.Authorization
  alias Phoenix.LiveView
  alias Phoenix.Controller

  # Import verified routes for ~p sigil
  use Phoenix.VerifiedRoutes,
    endpoint: CuratorianWeb.Endpoint,
    router: CuratorianWeb.Router,
    statics: CuratorianWeb.static_paths()

  @doc """
  Use this in LiveViews to ensure authorization.

  ## Examples

      # Require specific permission
      on_mount {CuratorianWeb.Authorization, {:require_permission, "blogs:create"}}

      # Require specific role
      on_mount {CuratorianWeb.Authorization, {:require_role, "super_admin"}}

      # Require super admin
      on_mount {CuratorianWeb.Authorization, :require_super_admin}

      # Require manager or super admin
      on_mount {CuratorianWeb.Authorization, :require_manager}

  """
  def on_mount({:require_permission, permission_slug}, _params, _session, socket) do
    user = socket.assigns.current_scope.user

    if user && Authorization.user_has_permission?(user, permission_slug) do
      {:cont, socket}
    else
      socket =
        socket
        |> LiveView.put_flash(:error, "You don't have permission to access this page.")
        |> LiveView.redirect(to: ~p"/dashboard")

      {:halt, socket}
    end
  end

  def on_mount({:require_role, role_slug}, _params, _session, socket) do
    user = socket.assigns.current_scope.user

    if user && Authorization.user_has_role?(user, role_slug) do
      {:cont, socket}
    else
      socket =
        socket
        |> LiveView.put_flash(:error, "You don't have the required role to access this page.")
        |> LiveView.redirect(to: ~p"/dashboard")

      {:halt, socket}
    end
  end

  def on_mount(:require_super_admin, _params, _session, socket) do
    user = socket.assigns.current_scope.user

    if user && Authorization.is_super_admin?(user) do
      {:cont, socket}
    else
      socket =
        socket
        |> LiveView.put_flash(:error, "You must be a super admin to access this page.")
        |> LiveView.redirect(to: ~p"/dashboard")

      {:halt, socket}
    end
  end

  def on_mount(:require_manager, _params, _session, socket) do
    user = socket.assigns.current_scope.user

    if user && Authorization.is_manager?(user) do
      {:cont, socket}
    else
      socket =
        socket
        |> LiveView.put_flash(:error, "You must be a manager to access this page.")
        |> LiveView.redirect(to: ~p"/dashboard")

      {:halt, socket}
    end
  end

  # ============================================================================
  # CONTROLLER PLUGS
  # ============================================================================

  @doc """
  Plug to ensure user has a specific permission.

  ## Examples

      plug CuratorianWeb.Authorization, {:require_permission, "blogs:create"}

  """
  def init(opts), do: opts

  def call(conn, {:require_permission, permission_slug}) do
    user = conn.assigns.current_scope.user

    if user && Authorization.user_has_permission?(user, permission_slug) do
      conn
    else
      conn
      |> Controller.put_flash(:error, "You don't have permission to access this page.")
      |> Controller.redirect(to: ~p"/dashboard")
      |> halt()
    end
  end

  def call(conn, {:require_role, role_slug}) do
    user = conn.assigns.current_scope.user

    if user && Authorization.user_has_role?(user, role_slug) do
      conn
    else
      conn
      |> Controller.put_flash(:error, "You don't have the required role to access this page.")
      |> Controller.redirect(to: ~p"/dashboard")
      |> halt()
    end
  end

  def call(conn, :require_super_admin) do
    user = conn.assigns.current_scope.user

    if user && Authorization.is_super_admin?(user) do
      conn
    else
      conn
      |> Controller.put_flash(:error, "You must be a super admin to access this page.")
      |> Controller.redirect(to: ~p"/dashboard")
      |> halt()
    end
  end

  def call(conn, :require_manager) do
    user = conn.assigns.current_scope.user

    if user && Authorization.is_manager?(user) do
      conn
    else
      conn
      |> Controller.put_flash(:error, "You must be a manager to access this page.")
      |> Controller.redirect(to: ~p"/dashboard")
      |> halt()
    end
  end

  # ============================================================================
  # VIEW HELPERS
  # ============================================================================

  @doc """
  Helper function to check if user has permission in templates.

  ## Examples

      <%= if can?(@current_scope.user, "blogs:create") do %>
        <.link>Create Blog</.link>
      <% end %>

  """
  def can?(user, permission_slug) do
    Authorization.user_has_permission?(user, permission_slug)
  end

  @doc """
  Helper function to check if user can perform action on resource in templates.

  ## Examples

      <%= if can?(@current_scope.user, "blogs", "create") do %>
        <.link>Create Blog</.link>
      <% end %>

  """
  def can?(user, resource, action) do
    Authorization.user_can?(user, resource, action)
  end

  @doc """
  Helper function to check if user has a role in templates.

  ## Examples

      <%= if has_role?(@current_scope.user, "super_admin") do %>
        <.link>Admin Panel</.link>
      <% end %>

  """
  def has_role?(user, role_slug) do
    Authorization.user_has_role?(user, role_slug)
  end

  @doc """
  Helper function to check if user is super admin in templates.
  """
  def is_super_admin?(user) do
    Authorization.is_super_admin?(user)
  end

  @doc """
  Helper function to check if user is manager in templates.
  """
  def is_manager?(user) do
    Authorization.is_manager?(user)
  end
end
