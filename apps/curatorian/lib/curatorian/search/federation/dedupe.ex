defmodule Curatorian.Search.Federation.Dedupe do
  @moduledoc """
  Cheap, deterministic cross-source deduplication (spec §8.4).

  Merge only when: DOI equal, Internet Archive identifier equal, or ISBN
  intersects. The richer record wins; the other source is attached as
  `extra.also_at` (list of its URLs). **Never** merges an external record
  into a local one, and no fuzzy title matching.
  """

  alias Curatorian.Search.Result

  # Deterministic survivor choice: results arrive from async tasks in any
  # order, so sort by source priority before merging (a map's key order alone
  # is not enough once providers resolve at different times).
  @source_priority %{open_library: 0, openalex: 1, internet_archive: 2}

  @doc "Returns `{kept_results, hidden_count}` — duplicates are folded into survivors."
  def run(results_by_provider) when is_map(results_by_provider) do
    all =
      results_by_provider
      |> Map.values()
      |> List.flatten()
      |> Enum.sort_by(&{Map.get(@source_priority, &1.source, 3), &1.source_id})

    {kept_rev, hidden} =
      Enum.reduce(all, {[], 0}, fn result, {kept, hidden} ->
        case Enum.find(kept, &same_item?(&1, result)) do
          nil ->
            {[result | kept], hidden}

          dup ->
            # Merged identifiers flow into the survivor, so a third record
            # matching either original still lands on the same survivor.
            {replace(kept, dup, result), hidden + 1}
        end
      end)

    {Enum.reverse(kept_rev), hidden}
  end

  defp replace(kept, dup, result) do
    Enum.map(kept, fn r -> if r == dup, do: merge(r, result), else: r end)
  end

  defp same_item?(%Result{} = a, %Result{} = b) do
    doi_eq?(a, b) or ia_eq?(a, b) or isbn_intersect?(a, b)
  end

  defp doi_eq?(a, b) do
    a_doi = a.identifiers[:doi] && String.downcase(a.identifiers[:doi])
    b_doi = b.identifiers[:doi] && String.downcase(b.identifiers[:doi])
    a_doi != nil and a_doi == b_doi
  end

  defp ia_eq?(a, b) do
    a_ia = MapSet.new(a.identifiers[:ia] || [])
    b_ia = b.identifiers[:ia] || []
    b_ia != [] and Enum.any?(b_ia, &MapSet.member?(a_ia, &1))
  end

  defp isbn_intersect?(a, b) do
    a_isbn = MapSet.new(isbns(a))
    b_isbn = isbns(b)
    b_isbn != [] and Enum.any?(b_isbn, &MapSet.member?(a_isbn, &1))
  end

  defp isbns(%Result{identifiers: ids}) when is_map(ids) do
    case ids[:isbn] do
      list when is_list(list) -> Enum.map(list, &normalize_isbn/1)
      isbn when is_binary(isbn) -> [normalize_isbn(isbn)]
      _ -> []
    end
  end

  defp normalize_isbn(isbn), do: isbn |> String.replace("-", "") |> String.downcase()

  # Keep the richer record: non-nil fields win; attach the other source.
  defp merge(a, b) do
    merged_ids = MapSet.new([a.source_id, b.source_id | a.extra[:merged_ids] || []])

    %Result{
      a
      | title: a.title || b.title,
        creators: non_empty(a.creators, b.creators),
        year: a.year || b.year,
        description: first_non_nil(a.description, b.description),
        thumbnail_url: first_non_nil(a.thumbnail_url, b.thumbnail_url),
        languages: non_empty(a.languages, b.languages),
        access: better_access(a.access, b.access),
        rights: first_non_nil(a.rights, b.rights),
        read_url: first_non_nil(a.read_url, b.read_url),
        identifiers: Map.merge(b.identifiers || %{}, a.identifiers || %{}),
        extra:
          a.extra
          |> Map.merge(%{
            also_at: [b.url | a.extra[:also_at] || []],
            also_at_source: [b.source | a.extra[:also_at_source] || []],
            merged_ids: MapSet.to_list(merged_ids)
          })
    }
  end

  defp non_empty(a, _b) when is_list(a) and a != [], do: a
  defp non_empty(_a, b) when is_list(b), do: b
  defp non_empty(a, _b), do: a

  defp first_non_nil(a, _b) when not is_nil(a), do: a
  defp first_non_nil(_a, b), do: b

  defp better_access(:open, _), do: :open
  defp better_access(_, :open), do: :open
  defp better_access(:borrowable, _), do: :borrowable
  defp better_access(_, :borrowable), do: :borrowable
  defp better_access(a, _b), do: a
end
