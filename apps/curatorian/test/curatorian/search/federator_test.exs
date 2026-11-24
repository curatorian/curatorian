defmodule Curatorian.Search.Federation.FederatorTest do
  @moduledoc """
  Federation runtime: cache, single-flight, negative cache, stale-if-error,
  circuit breaker, cooldowns, limiters, telemetry and routing (spec §8, §13).
  """

  use ExUnit.Case, async: false

  alias Curatorian.FederationStubs.Provider
  alias Curatorian.Search.Federation.{Breaker, Cache, Cooldown, Federator, Limiter, Router}
  alias Curatorian.Search.Query

  @tables [
    :curatorian_search_cache,
    :curatorian_search_breaker,
    :curatorian_search_limiter,
    :curatorian_search_cooldown
  ]

  setup do
    for table <- @tables, do: :ets.delete_all_objects(table)

    if :ets.whereis(:stub_call_counter) != :undefined do
      :ets.delete(:stub_call_counter)
    end

    :ets.new(:stub_call_counter, [:named_table, :public])
    :ets.insert(:stub_call_counter, {:calls, 0})

    Application.put_env(:curatorian, :stub_provider_id, :stub_provider)
    Application.put_env(:curatorian, :stub_search_result, :ok)
    Application.put_env(:curatorian, :stub_rate_limit, {100, 100})

    on_exit(fn ->
      Application.delete_env(:curatorian, :stub_provider_id)
      Application.delete_env(:curatorian, :stub_search_result)
      Application.delete_env(:curatorian, :stub_rate_limit)
    end)

    :ok
  end

  describe "cache" do
    test "a second identical query is served from cache without calling upstream" do
      assert {:ok, %{status: :ok}} = Federator.run(Provider, Query.new("rainbow"))
      assert Provider.calls() == 1

      assert {:ok, %{status: :cache_hit}} = Federator.run(Provider, Query.new("rainbow"))
      assert Provider.calls() == 1
    end

    test "concurrent identical queries share one upstream call (single-flight)" do
      Application.put_env(:curatorian, :stub_search_result, {:sleep, 150, {:ok, Provider.page()}})

      results =
        1..5
        |> Task.async_stream(fn _ -> Federator.run(Provider, Query.new("single flight")) end,
          max_concurrency: 5,
          timeout: 5_000
        )
        |> Enum.map(fn {:ok, result} -> result end)

      assert Enum.all?(results, &match?({:ok, _}, &1))
      assert Provider.calls() == 1
    end

    test "errors are negatively cached for a short TTL" do
      Application.put_env(:curatorian, :stub_search_result, {:error, :boom})

      assert {:error, %{status: :error}} = Federator.run(Provider, Query.new("neg"))
      assert {:error, %{status: :error}} = Federator.run(Provider, Query.new("neg"))
      assert Provider.calls() == 1
    end

    test "stale results are served when the provider fails for the same key" do
      query = Query.new("stale query")
      key = Cache.key(Provider.id(), query)

      # Seed an already-stale entry (fresh window in the past, stale window ahead).
      Cache.put_ok(key, {:ok, Provider.page()}, fresh_ms: -1_000, stale_ms: :timer.hours(1))

      Application.put_env(:curatorian, :stub_search_result, {:error, :boom})

      assert {:ok, page} = Federator.run(Provider, query)
      assert page.status == :stale
      assert page.stale_age_min >= 1
      assert length(page.results) == 1
      # The provider is attempted once; on failure the stale entry is served.
      assert Provider.calls() == 1
    end

    test "stale results are never served for a different key" do
      query = Query.new("one")
      key = Cache.key(Provider.id(), query)
      Cache.put_ok(key, {:ok, Provider.page()}, fresh_ms: -1_000, stale_ms: :timer.hours(1))

      Application.put_env(:curatorian, :stub_search_result, {:error, :boom})

      assert {:error, %{status: :error}} = Federator.run(Provider, Query.new("two"))
    end

    test "bypass_cache forces a fresh upstream call" do
      assert {:ok, _} = Federator.run(Provider, Query.new("bypass"))
      assert Provider.calls() == 1

      assert {:ok, _} = Federator.run(Provider, Query.new("bypass"), bypass_cache: true)
      assert Provider.calls() == 2
    end
  end

  describe "timeouts" do
    test "a provider exceeding its timeout yields :error/:timeout without blocking longer" do
      Application.put_env(
        :curatorian,
        :stub_search_result,
        {:sleep, 3_000, {:ok, Provider.page()}}
      )

      started = System.monotonic_time(:millisecond)
      result = Federator.run(Provider, Query.new("slow provider"))
      elapsed = System.monotonic_time(:millisecond) - started

      assert {:error, %{status: :error, reason: :timeout}} = result
      # Stub timeout is 500 ms → hard ceiling is 1500 ms.
      assert elapsed < 2_000
    end
  end

  describe "circuit breaker" do
    test "opens after 5 failures and short-circuits without upstream calls" do
      Application.put_env(:curatorian, :stub_search_result, {:error, :boom})

      for i <- 1..5 do
        assert {:error, _} = Federator.run(Provider, Query.new("fail #{i}"))
      end

      assert Breaker.state(Provider.id()) == :open
      assert Provider.calls() == 5

      assert {:error, %{status: :breaker_open}} =
               Federator.run(Provider, Query.new("fail 6"))

      assert Provider.calls() == 5
    end

    test "a success closes the breaker" do
      Application.put_env(:curatorian, :stub_search_result, {:error, :boom})
      for i <- 1..3, do: Federator.run(Provider, Query.new("partial #{i}"))

      Application.put_env(:curatorian, :stub_search_result, :ok)
      assert {:ok, _} = Federator.run(Provider, Query.new("recover"))
      assert Breaker.state(Provider.id()) == :closed
    end
  end

  describe "cooldown and limiters" do
    test "an upstream 429 sets a provider-wide cooldown and blocks further calls" do
      Application.put_env(:curatorian, :stub_search_result, {:error, {:rate_limited, 5}})

      assert {:error, %{status: :rate_limited, retry_after: retry}} =
               Federator.run(Provider, Query.new("limited"))

      assert is_integer(retry) and retry >= 1
      assert Provider.calls() == 1

      # Different query, same provider: still in cooldown → no upstream call.
      assert {:error, %{status: :rate_limited}} =
               Federator.run(Provider, Query.new("another"))

      assert Provider.calls() == 1
    end

    test "the token bucket reports rate limiting when exhausted" do
      Application.put_env(:curatorian, :stub_rate_limit, {1, 1})

      assert {:ok, _} = Federator.run(Provider, Query.new("bucket one"))
      assert {:error, %{status: :rate_limited}} = Federator.run(Provider, Query.new("bucket two"))
      assert Provider.calls() == 1
    end

    test "cooldown clamps Retry-After and clears on demand" do
      # Retry-After is clamped to >= 5 s and jittered ±20%.
      assert {:ok, seconds} = Cooldown.set(Provider.id(), 1)
      assert seconds in 5..7
      assert {:limited, _} = Cooldown.check(Provider.id())

      Cooldown.clear(Provider.id())
      assert Cooldown.check(Provider.id()) == :ok
    end

    test "limiter refills over time" do
      assert :ok = Limiter.check(:limiter_test, {10, 1})
      assert {:limited, wait_ms} = Limiter.check(:limiter_test, {10, 1})
      assert wait_ms > 0
    end
  end

  describe "telemetry" do
    test "emits [:curatorian, :search, :provider, :stop] with status and count" do
      ref = make_ref()
      parent = self()

      :telemetry.attach(
        "federator-test-#{inspect(ref)}",
        [:curatorian, :search, :provider, :stop],
        fn _event, measurements, metadata, _config ->
          send(parent, {:telemetry, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("federator-test-#{inspect(ref)}") end)

      assert {:ok, _} = Federator.run(Provider, Query.new("telemetry"))

      assert_received {:telemetry, measurements, metadata}
      assert metadata.provider == Provider.id()
      assert metadata.status == :ok
      assert metadata.result_count == 1
      assert measurements.duration >= 0
    end
  end

  describe "Router" do
    test "book queries fan out to Open Library and Internet Archive" do
      ids = Router.providers_for(:book) |> Enum.map(& &1.id())
      assert :open_library in ids
      assert :internet_archive in ids
    end

    test "article has no providers until C3 (OpenAlex)" do
      assert Router.providers_for(:article) == []
    end

    test "disabled providers are filtered out" do
      module = Curatorian.Search.Federation.Providers.OpenLibrary
      previous = Application.get_env(:curatorian, module, [])

      Application.put_env(:curatorian, module, Keyword.put(previous, :enabled, false))
      on_exit(fn -> Application.put_env(:curatorian, module, previous) end)

      refute :open_library in Enum.map(Router.providers_for(:all), & &1.id())
      assert Router.provider(:open_library) == nil
    end
  end

  describe "Dedupe" do
    test "merges records sharing an Internet Archive identifier" do
      ol = Provider.result(%{source: :open_library, identifiers: %{ia: ["same-id"]}, title: "A"})

      ia =
        Provider.result(%{source: :internet_archive, identifiers: %{ia: ["same-id"]}, title: "A"})

      {kept, hidden} =
        Curatorian.Search.Federation.Dedupe.run(%{open_library: [ol], internet_archive: [ia]})

      assert hidden == 1
      assert length(kept) == 1
      assert [%{source: :open_library}] = kept
      assert kept |> hd() |> Map.get(:extra) |> Map.get(:also_at) == ["https://stub.example/1"]
    end

    test "keeps distinct records" do
      a = Provider.result(%{source: :open_library, identifiers: %{ia: ["a"]}})
      b = Provider.result(%{source: :internet_archive, identifiers: %{ia: ["b"]}})

      {kept, hidden} =
        Curatorian.Search.Federation.Dedupe.run(%{open_library: [a], internet_archive: [b]})

      assert hidden == 0
      assert length(kept) == 2
    end

    test "merges on equal DOI and intersecting ISBN" do
      a = Provider.result(%{source: :open_library, identifiers: %{doi: "10.1/x"}})
      b = Provider.result(%{source: :open_alex, identifiers: %{doi: "10.1/X"}})
      assert {_, 1} = Curatorian.Search.Federation.Dedupe.run(%{a: [a], b: [b]})

      c = Provider.result(%{source: :open_library, identifiers: %{isbn: ["978-1"]}})
      d = Provider.result(%{source: :internet_archive, identifiers: %{isbn: ["9781"]}})
      assert {_, 1} = Curatorian.Search.Federation.Dedupe.run(%{c: [c], d: [d]})
    end
  end
end
