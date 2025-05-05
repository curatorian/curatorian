defmodule Curatorian.OrgsTest do
  use Curatorian.DataCase

  alias Curatorian.Orgs

  describe "organizations" do
    alias Curatorian.Orgs.Organization

    import Curatorian.OrgsFixtures

    @invalid_attrs %{name: nil, status: nil, type: nil, description: nil, slug: nil, image_logo: nil, image_cover: nil}

    test "list_organizations/0 returns all organizations" do
      organization = organization_fixture()
      assert Orgs.list_organizations() == [organization]
    end

    test "get_organization!/1 returns the organization with given id" do
      organization = organization_fixture()
      assert Orgs.get_organization!(organization.id) == organization
    end

    test "create_organization/1 with valid data creates a organization" do
      valid_attrs = %{name: "some name", status: "some status", type: "some type", description: "some description", slug: "some slug", image_logo: "some image_logo", image_cover: "some image_cover"}

      assert {:ok, %Organization{} = organization} = Orgs.create_organization(valid_attrs)
      assert organization.name == "some name"
      assert organization.status == "some status"
      assert organization.type == "some type"
      assert organization.description == "some description"
      assert organization.slug == "some slug"
      assert organization.image_logo == "some image_logo"
      assert organization.image_cover == "some image_cover"
    end

    test "create_organization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Orgs.create_organization(@invalid_attrs)
    end

    test "update_organization/2 with valid data updates the organization" do
      organization = organization_fixture()
      update_attrs = %{name: "some updated name", status: "some updated status", type: "some updated type", description: "some updated description", slug: "some updated slug", image_logo: "some updated image_logo", image_cover: "some updated image_cover"}

      assert {:ok, %Organization{} = organization} = Orgs.update_organization(organization, update_attrs)
      assert organization.name == "some updated name"
      assert organization.status == "some updated status"
      assert organization.type == "some updated type"
      assert organization.description == "some updated description"
      assert organization.slug == "some updated slug"
      assert organization.image_logo == "some updated image_logo"
      assert organization.image_cover == "some updated image_cover"
    end

    test "update_organization/2 with invalid data returns error changeset" do
      organization = organization_fixture()
      assert {:error, %Ecto.Changeset{}} = Orgs.update_organization(organization, @invalid_attrs)
      assert organization == Orgs.get_organization!(organization.id)
    end

    test "delete_organization/1 deletes the organization" do
      organization = organization_fixture()
      assert {:ok, %Organization{}} = Orgs.delete_organization(organization)
      assert_raise Ecto.NoResultsError, fn -> Orgs.get_organization!(organization.id) end
    end

    test "change_organization/1 returns a organization changeset" do
      organization = organization_fixture()
      assert %Ecto.Changeset{} = Orgs.change_organization(organization)
    end
  end

  describe "organization_roles" do
    alias Curatorian.Orgs.OrganizationRole

    import Curatorian.OrgsFixtures

    @invalid_attrs %{label: nil, slug: nil}

    test "list_organization_roles/0 returns all organization_roles" do
      organization_role = organization_role_fixture()
      assert Orgs.list_organization_roles() == [organization_role]
    end

    test "get_organization_role!/1 returns the organization_role with given id" do
      organization_role = organization_role_fixture()
      assert Orgs.get_organization_role!(organization_role.id) == organization_role
    end

    test "create_organization_role/1 with valid data creates a organization_role" do
      valid_attrs = %{label: "some label", slug: "some slug"}

      assert {:ok, %OrganizationRole{} = organization_role} = Orgs.create_organization_role(valid_attrs)
      assert organization_role.label == "some label"
      assert organization_role.slug == "some slug"
    end

    test "create_organization_role/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Orgs.create_organization_role(@invalid_attrs)
    end

    test "update_organization_role/2 with valid data updates the organization_role" do
      organization_role = organization_role_fixture()
      update_attrs = %{label: "some updated label", slug: "some updated slug"}

      assert {:ok, %OrganizationRole{} = organization_role} = Orgs.update_organization_role(organization_role, update_attrs)
      assert organization_role.label == "some updated label"
      assert organization_role.slug == "some updated slug"
    end

    test "update_organization_role/2 with invalid data returns error changeset" do
      organization_role = organization_role_fixture()
      assert {:error, %Ecto.Changeset{}} = Orgs.update_organization_role(organization_role, @invalid_attrs)
      assert organization_role == Orgs.get_organization_role!(organization_role.id)
    end

    test "delete_organization_role/1 deletes the organization_role" do
      organization_role = organization_role_fixture()
      assert {:ok, %OrganizationRole{}} = Orgs.delete_organization_role(organization_role)
      assert_raise Ecto.NoResultsError, fn -> Orgs.get_organization_role!(organization_role.id) end
    end

    test "change_organization_role/1 returns a organization_role changeset" do
      organization_role = organization_role_fixture()
      assert %Ecto.Changeset{} = Orgs.change_organization_role(organization_role)
    end
  end

  describe "organization_users" do
    alias Curatorian.Orgs.OrganizationUser

    import Curatorian.OrgsFixtures

    @invalid_attrs %{joined_at: nil}

    test "list_organization_users/0 returns all organization_users" do
      organization_user = organization_user_fixture()
      assert Orgs.list_organization_users() == [organization_user]
    end

    test "get_organization_user!/1 returns the organization_user with given id" do
      organization_user = organization_user_fixture()
      assert Orgs.get_organization_user!(organization_user.id) == organization_user
    end

    test "create_organization_user/1 with valid data creates a organization_user" do
      valid_attrs = %{joined_at: ~U[2025-05-04 14:13:00Z]}

      assert {:ok, %OrganizationUser{} = organization_user} = Orgs.create_organization_user(valid_attrs)
      assert organization_user.joined_at == ~U[2025-05-04 14:13:00Z]
    end

    test "create_organization_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Orgs.create_organization_user(@invalid_attrs)
    end

    test "update_organization_user/2 with valid data updates the organization_user" do
      organization_user = organization_user_fixture()
      update_attrs = %{joined_at: ~U[2025-05-05 14:13:00Z]}

      assert {:ok, %OrganizationUser{} = organization_user} = Orgs.update_organization_user(organization_user, update_attrs)
      assert organization_user.joined_at == ~U[2025-05-05 14:13:00Z]
    end

    test "update_organization_user/2 with invalid data returns error changeset" do
      organization_user = organization_user_fixture()
      assert {:error, %Ecto.Changeset{}} = Orgs.update_organization_user(organization_user, @invalid_attrs)
      assert organization_user == Orgs.get_organization_user!(organization_user.id)
    end

    test "delete_organization_user/1 deletes the organization_user" do
      organization_user = organization_user_fixture()
      assert {:ok, %OrganizationUser{}} = Orgs.delete_organization_user(organization_user)
      assert_raise Ecto.NoResultsError, fn -> Orgs.get_organization_user!(organization_user.id) end
    end

    test "change_organization_user/1 returns a organization_user changeset" do
      organization_user = organization_user_fixture()
      assert %Ecto.Changeset{} = Orgs.change_organization_user(organization_user)
    end
  end
end
