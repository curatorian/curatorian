defmodule Curatorian.PublicCollectionsSearchTest do
  # The shared test database contains pre-existing catalog data, so every
  # assertion is scoped by unique tokens / membership — never exact totals.
  use Curatorian.DataCase, async: false

  import Curatorian.CollectionsFixtures

  alias Curatorian.Public

  describe "search_collections/1" do
    test "returns published public collections, newest first when browsing" do
      # Distinct timestamps: timestamps() only autogenerates nil fields.
      {col1, _, _} =
        collection_fixture(title: "Zebra Koleksi 44001", inserted_at: ~U[2026-01-01 08:00:00Z])

      {col2, _, _} =
        collection_fixture(title: "Zebra Koleksi 44002", inserted_at: ~U[2026-01-02 08:00:00Z])

      results = Public.search_collections(sort: "newest", search: "Zebra Koleksi")

      assert Enum.map(results, & &1.id) == [col2.id, col1.id]
    end

    test "searches by title through full-text search" do
      {col, _, _} = collection_fixture(title: "Laskar Pelangi Kisah Unik 9812")
      collection_fixture()

      results = Public.search_collections(search: "9812")

      assert [%{id: id}] = results
      assert id == col.id
    end

    test "excludes draft, private and archived collections" do
      {published, _, _} = collection_fixture(title: "Zebra Visibilitas 33001")
      {draft, _, _} = collection_fixture(title: "Zebra Visibilitas 33002", status: "draft")

      {private, _, _} =
        collection_fixture(title: "Zebra Visibilitas 33003", access_level: "private")

      {archived, _, _} = collection_fixture(title: "Zebra Visibilitas 33004", status: "archived")

      results = Public.search_collections(search: "Zebra Visibilitas")
      ids = Enum.map(results, & &1.id)

      assert published.id in ids
      refute draft.id in ids
      refute private.id in ids
      refute archived.id in ids
    end

    test "filters by glam type" do
      {library_col, _, _} = collection_fixture(title: "Zebra Sektor 22001")
      museum_rc = resource_class_fixture(glam_type: "Museum")

      {museum_col, _, _} =
        collection_fixture(title: "Zebra Sektor 22002", resource_class: museum_rc)

      results = Public.search_collections(search: "Zebra Sektor", glam_type: "Museum")
      ids = Enum.map(results, & &1.id)

      assert museum_col.id in ids
      refute library_col.id in ids
    end

    test "filters by collection type" do
      {book, _, _} = collection_fixture(title: "Zebra Jenis 11001", collection_type: "book")
      {movie, _, _} = collection_fixture(title: "Zebra Jenis 11002", collection_type: "movie")

      results = Public.search_collections(search: "Zebra Jenis", collection_type: "book")
      ids = Enum.map(results, & &1.id)

      assert book.id in ids
      refute movie.id in ids
    end

    test "filters by dublin core subject" do
      {col, _, _} = collection_fixture(title: "Zebra Subjek 55001")
      collection_field_fixture(col, name: "dc:subject", value: "Biografi Zebra 55001")

      {other, _, _} = collection_fixture(title: "Zebra Subjek 55002")
      collection_field_fixture(other, name: "dc:subject", value: "Psikologi")

      results = Public.search_collections(subject: "Biografi Zebra 55001")
      ids = Enum.map(results, & &1.id)

      assert col.id in ids
      refute other.id in ids
    end

    test "filters by province from the owning node profile" do
      {col, unit, _} = collection_fixture(title: "Zebra Lokasi 66001")
      node_profile_fixture(unit, province: "Sumedang Zebra", city: "Sumedang")
      collection_fixture(title: "Zebra Lokasi 66002")

      results = Public.search_collections(province: "Sumedang Zebra")
      ids = Enum.map(results, & &1.id)

      assert col.id in ids
    end

    test "sorts by title when requested" do
      collection_fixture(title: "Zebra Urut Aaa 77001")
      collection_fixture(title: "Zebra Urut Bbb 77002")

      results = Public.search_collections(search: "Zebra Urut", sort: "title")

      assert Enum.map(results, & &1.title) == Enum.sort(Enum.map(results, & &1.title))
    end
  end

  describe "count_search_collections/1" do
    test "counts within the same filter set" do
      token = "ZebraHit#{System.unique_integer([:positive])}"
      collection_fixture(title: "#{token} Satu")
      collection_fixture(title: "#{token} Dua")
      collection_fixture(title: "#{token} Tiga", status: "draft")

      assert Public.count_search_collections(search: token) == 2
    end
  end

  describe "collection_search_facets/1" do
    test "counts organizations within the filtered set" do
      token = "ZebraOrg#{System.unique_integer([:positive])}"
      {_, unit1, _} = collection_fixture(title: "#{token} Satu")
      {_, unit2, _} = collection_fixture(title: "#{token} Dua")

      facets = Public.collection_search_facets(search: token)

      unit_facets = Map.new(facets.units, &{&1.value, &1})
      assert unit_facets[unit1.id].count == 1
      assert unit_facets[unit2.id].count == 1
      assert unit_facets[unit1.id].label == unit1.name
    end

    test "removes a facet's own selection so users can broaden" do
      token = "ZebraBroad#{System.unique_integer([:positive])}"
      {_, unit1, _} = collection_fixture(title: "#{token} Satu")
      {_, unit2, _} = collection_fixture(title: "#{token} Dua")

      facets = Public.collection_search_facets(search: token, node_id: unit1.id)

      values = Enum.map(facets.units, & &1.value)
      assert unit1.id in values
      assert unit2.id in values
    end

    test "subject facets come from collection_fields" do
      token = "ZebraDC#{System.unique_integer([:positive])}"
      {col, _, _} = collection_fixture(title: token)
      collection_field_fixture(col, name: "dc:subject", value: "Biografi #{token}")

      facets = Public.collection_search_facets(search: token)

      assert Enum.find(facets.subjects, &(&1.value == "Biografi #{token}"))
    end
  end
end
