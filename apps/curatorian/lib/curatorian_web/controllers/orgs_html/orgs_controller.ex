defmodule CuratorianWeb.OrgsController do
  use CuratorianWeb, :controller

  alias Curatorian.Repo
  alias Curatorian.Orgs

  def index(conn, _params) do
    current_user = conn.assigns[:current_scope] && conn.assigns.current_scope.user
    organizations = Orgs.list_organizations(current_user)

    conn
    |> assign(:organizations, organizations)
    |> assign(:page_title, "Organizations")
    |> render(:index)
  end

  def show(conn, %{"slug" => slug}) do
    member_count = Orgs.get_member_count_by_slug(slug)

    with {:ok, organization} <- safe_get_organization(slug) do
      current_user = conn.assigns[:current_scope] && conn.assigns.current_scope.user
      current_user = if current_user, do: Repo.preload(current_user, :roles), else: nil

      can_view? =
        organization.status == "approved" or
          (current_user &&
             (organization.owner_id == current_user.id or
                (current_user.roles && current_user.roles.name == "super_admin")))

      if can_view? do
        conn
        |> assign(:organization, organization)
        |> assign(:page_title, organization.name)
        |> assign(:member_count, member_count)
        |> render(:show)
      else
        conn
        |> put_flash(:error, "Organization not found")
        |> redirect(to: ~p"/orgs")
      end
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Organization not found")
        |> redirect(to: ~p"/orgs")
    end
  end

  def create(conn, %{"organization" => organization_params}) do
    current_user = conn.assigns.current_scope.user

    case Orgs.create_organization(current_user, organization_params) do
      {:ok, organization} ->
        conn
        |> put_flash(:info, "Organization created successfully.")
        |> redirect(to: ~p"/orgs/#{organization.slug}")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> assign(:page_title, "New Organization")
        |> render(:new)
    end
  end

  def edit(conn, %{"slug" => slug}) do
    with {:ok, organization} <- safe_get_organization(slug),
         true <- can_manage?(conn, organization) do
      conn
      |> redirect(to: ~p"/dashboard/orgs/#{organization.slug}/edit")
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Organization not found")
        |> redirect(to: ~p"/orgs")

      false ->
        conn
        |> put_flash(:error, "You don't have permission to edit this organization")
        |> redirect(to: ~p"/orgs")
    end
  end

  def update(conn, %{"slug" => slug, "organization" => organization_params}) do
    with {:ok, organization} <- safe_get_organization(slug),
         true <- can_manage?(conn, organization) do
      case Orgs.update_organization(organization, organization_params) do
        {:ok, organization} ->
          conn
          |> put_flash(:info, "Organization updated successfully.")
          |> redirect(to: ~p"/orgs/#{organization.slug}")

        {:error, %Ecto.Changeset{} = _changeset} ->
          conn
          |> put_flash(:error, "Failed to update organization.")
          |> redirect(to: ~p"/dashboard/orgs/#{organization.slug}/edit")
      end
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Organization not found")
        |> redirect(to: ~p"/orgs")

      false ->
        conn
        |> put_flash(:error, "You don't have permission to edit this organization")
        |> redirect(to: ~p"/orgs")
    end
  end

  def delete(conn, %{"slug" => slug}) do
    with {:ok, organization} <- safe_get_organization(slug),
         true <- can_manage?(conn, organization) do
      {:ok, _} = Orgs.delete_organization(organization)

      conn
      |> put_flash(:info, "Organization deleted successfully.")
      |> redirect(to: ~p"/orgs")
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Organization not found")
        |> redirect(to: ~p"/orgs")

      false ->
        conn
        |> put_flash(:error, "You don't have permission to delete this organization")
        |> redirect(to: ~p"/orgs")
    end
  end

  def join(conn, %{"slug" => slug}) do
    with {:ok, organization} <- safe_get_organization(slug) do
      current_user = conn.assigns.current_scope.user

      case Orgs.add_member(organization, current_user, "member") do
        {:ok, _} ->
          conn
          |> put_flash(:info, "Successfully joined organization.")
          |> redirect(to: ~p"/orgs/#{organization.slug}")

        {:error, _} ->
          conn
          |> put_flash(:error, "Failed to join organization. You may already be a member.")
          |> redirect(to: ~p"/orgs/#{organization.slug}")
      end
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Organization not found")
        |> redirect(to: ~p"/orgs")
    end
  end

  def leave(conn, %{"slug" => slug}) do
    with {:ok, organization} <- safe_get_organization(slug) do
      current_user = conn.assigns.current_scope.user

      case Orgs.remove_member(organization, current_user) do
        {1, _} ->
          conn
          |> put_flash(:info, "Successfully left organization.")
          |> redirect(to: ~p"/orgs/#{organization.slug}")

        _ ->
          conn
          |> put_flash(:error, "Failed to leave organization. You may not be a member.")
          |> redirect(to: ~p"/orgs/#{organization.slug}")
      end
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Organization not found")
        |> redirect(to: ~p"/orgs")
    end
  end

  # Helper functions

  defp safe_get_organization(slug) do
    try do
      org = Orgs.get_organization_by_slug(slug)
      # Ensure we preload the organization users with their respective users and roles
      org =
        Repo.preload(org, [
          :owner,
          organization_users: [user: [], organization_role: []]
        ])

      {:ok, org}
    rescue
      Ecto.NoResultsError -> {:error, :not_found}
    end
  end

  defp can_manage?(conn, organization) do
    current_user = conn.assigns.current_scope.user
    Orgs.has_permission?(organization, current_user, :manage_all)
  end
end
