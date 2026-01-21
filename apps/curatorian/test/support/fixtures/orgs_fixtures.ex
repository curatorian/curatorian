defmodule Curatorian.OrgsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Curatorian.Orgs` context.
  """

  @doc """
  Generate a unique organization slug.
  """
  def unique_organization_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a organization.
  """
  def organization_fixture(attrs \\ %{}) do
    {:ok, organization} =
      attrs
      |> Enum.into(%{
        description: "some description",
        image_cover: "some image_cover",
        image_logo: "some image_logo",
        name: "some name",
        slug: unique_organization_slug(),
        status: "some status",
        type: "some type"
      })
      |> Curatorian.Orgs.create_organization(%{})

    organization
  end

  @doc """
  Generate a unique organization_role slug.
  """
  def unique_organization_role_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a organization_role.
  """
  def organization_role_fixture(attrs \\ %{}) do
    {:ok, organization_role} =
      attrs
      |> Enum.into(%{
        label: "some label",
        slug: unique_organization_role_slug()
      })
      |> Curatorian.Orgs.create_organization_role()

    organization_role
  end

  @doc """
  Generate a organization_user.
  """
  def organization_user_fixture(attrs \\ %{}) do
    {:ok, organization_user} =
      attrs
      |> Enum.into(%{
        joined_at: ~U[2025-05-04 14:13:00Z]
      })
      |> Curatorian.Orgs.create_organization_user()

    organization_user
  end
end
