defmodule Curatorian.CollectionsFixtures do
  @moduledoc """
  Fixtures for the shared-database collection discovery search.

  `/collections` reads `voile.*` and `atrium.*` tables directly (hybrid data
  path), so fixtures insert rows into `voile.nodes`, `voile.resource_class`,
  `voile.collections`, `voile.collection_fields` and `atrium.node_profiles`
  through `Curatorian.Repo`. These are read-only schemas in production; the
  direct struct inserts here are test-only.
  """

  alias Curatorian.Repo
  alias Curatorian.Public.Collection
  alias Curatorian.Public.NodeProfile
  alias Curatorian.Public.Unit
  alias Voile.Schema.Catalog.CollectionField
  alias Voile.Schema.Metadata.ResourceClass

  @doc "A unique organization unit (voile.nodes)."
  def unit_fixture(attrs \\ %{}) do
    # The Unit schema mirrors voile.nodes with `autogenerate: false` (serial
    # id), so the returned struct does not carry the DB-generated id — fetch
    # the row back by its unique name.
    name = "Perpustakaan Uji #{System.unique_integer([:positive])}"

    %Unit{name: name}
    |> struct_merge(attrs)
    |> Repo.insert!()

    Repo.get_by!(Unit, name: name)
  end

  @doc "A resource class (GLAM sector grouping)."
  def resource_class_fixture(attrs \\ %{}) do
    %ResourceClass{
      label: "Kelas Uji #{System.unique_integer([:positive])}",
      local_name: "uji-#{System.unique_integer([:positive])}",
      glam_type: "Library"
    }
    |> struct_merge(attrs)
    |> Repo.insert!()
  end

  @doc "An approved node profile (atrium) for a unit, with location data."
  def node_profile_fixture(unit, attrs \\ %{}) do
    %NodeProfile{
      # binary_id column without a DB default — generate client-side.
      id: Ecto.UUID.generate(),
      voile_node_id: unit.id,
      node_type: :organization,
      institution_type: :library,
      status: :approved,
      province: "Jawa Barat",
      city: "Kota Bandung"
    }
    |> struct_merge(attrs)
    |> Repo.insert!()
  end

  @doc "A master creator (voile.mst_creator)."
  def creator_fixture(attrs \\ %{}) do
    %Voile.Schema.Master.Creator{
      type: "Person",
      creator_name: "Pengarang Uji #{System.unique_integer([:positive])}"
    }
    |> struct_merge(attrs)
    |> Repo.insert!()
  end

  @doc """
  A public collection owned by a unit. Returns `{collection, unit, resource_class}`.
  Creates a fresh unit and resource class per call so tests stay isolated.
  """
  def collection_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    {unit, attrs} = Map.pop(attrs, :unit, unit_fixture())
    {resource_class, attrs} = Map.pop(attrs, :resource_class, resource_class_fixture())
    {creator, attrs} = Map.pop(attrs, :creator, creator_fixture())

    collection =
      %Collection{
        id: Ecto.UUID.generate(),
        title: "Laskar Pelangi #{System.unique_integer([:positive])}",
        description: "Kisah sepuluh anak Belitung yang berani bermimpi tinggi.",
        status: "published",
        access_level: "public",
        collection_type: "book",
        collection_code: collection_code(),
        creator_id: creator.id,
        unit_id: unit.id,
        type_id: resource_class.id
      }
      |> struct_merge(attrs)
      |> Repo.insert!()

    {collection, unit, resource_class}
  end

  defp collection_code do
    hex =
      System.unique_integer([:positive]) |> Integer.to_string(16) |> String.pad_leading(8, "0")

    "COL/UNITEST/BOOK/#{hex}"
  end

  @doc "A Dublin Core metadata property (voile.metadata_properties)."
  def property_fixture(attrs \\ %{}) do
    %Voile.Schema.Metadata.Property{
      label: "Properti Uji #{System.unique_integer([:positive])}",
      local_name: "uji-#{System.unique_integer([:positive])}",
      type_value: "literal"
    }
    |> struct_merge(attrs)
    |> Repo.insert!()
  end

  @doc "A Dublin Core metadata row for a collection (subject/language/creator)."
  def collection_field_fixture(collection, attrs \\ %{}) do
    {property, attrs} = attrs |> Map.new() |> Map.pop(:property, property_fixture())

    %CollectionField{
      collection_id: collection.id,
      name: "dc:subject",
      value: "Fiksi",
      label: "Subject",
      type_value: "literal",
      property_id: property.id
    }
    |> struct_merge(attrs)
    |> Repo.insert!()
  end

  defp struct_merge(struct, attrs) do
    Enum.reduce(attrs, struct, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end
end
