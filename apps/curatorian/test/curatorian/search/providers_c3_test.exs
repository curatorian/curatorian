defmodule Curatorian.Search.ProvidersC3Test do
  @moduledoc """
  C3 providers — OpenAlex, Gutendex, DOAB — plus the OpenAlex budget guard
  (spec §9.3–§9.5, §8.7.7).
  """

  use ExUnit.Case, async: false

  alias Curatorian.Search.Federation.{Budget, Provider}
  alias Curatorian.Search.Federation.Providers.{Doab, Gutendex, OpenAlex}
  alias Curatorian.Search.Query

  @oa Path.expand("../../support/fixtures/search/open_alex/search.json", __DIR__)
  @oa_limit Path.expand("../../support/fixtures/search/open_alex/rate_limit.json", __DIR__)
  @oa_limit_live Path.expand(
                   "../../support/fixtures/search/open_alex/rate_limit_live.json",
                   __DIR__
                 )
  @gutenberg Path.expand("../../support/fixtures/search/gutendex/search.json", __DIR__)
  @doab Path.expand("../../support/fixtures/search/doab/search.json", __DIR__)

  defp fixture!(path), do: path |> File.read!() |> Jason.decode!()

  defp set_config(module, opts) do
    previous = Application.get_env(:curatorian, module, [])
    Application.put_env(:curatorian, module, Keyword.merge(previous, opts))
    on_exit(fn -> Application.put_env(:curatorian, module, previous) end)
  end

  setup do
    Budget.clear()
    :ok
  end

  describe "OpenAlex" do
    test "is disabled without an API key" do
      set_config(OpenAlex, api_key: nil, enabled: true, base_url: "https://stub.invalid")
      refute OpenAlex.enabled?()
    end

    test "normalizes a work: creators, DOI, OA url, venue" do
      set_config(OpenAlex, api_key: "test-key")
      [work | _] = fixture!(@oa)["results"]

      result = OpenAlex.normalize(work)

      assert result.source == :open_alex
      assert result.title == "Open Access and the Commons"
      assert result.creators == ["Jane Doe", "Budi Santoso"]
      assert result.year == 2023
      assert result.kind == :article
      assert result.access == :open
      assert result.url == "https://journal.example.org/article/1.pdf"
      assert result.identifiers.doi == "10.1234/abc.2023"
      assert result.extra.venue == "Journal of Open Knowledge"
    end

    test "maps non-OA work to restricted and falls back to landing/doi url" do
      set_config(OpenAlex, api_key: "test-key")
      work = Enum.at(fixture!(@oa)["results"], 1)

      result = OpenAlex.normalize(work)

      assert result.access == :restricted
      assert result.kind == :article
      assert result.url == "https://openalex.org/W999"
    end

    test "returns nil for unusable works" do
      assert OpenAlex.normalize(%{}) == nil
      assert OpenAlex.normalize(nil) == nil
      assert OpenAlex.normalize("x") == nil
    end

    test "searching with an exhausted budget makes no HTTP call" do
      set_config(OpenAlex, api_key: "test-key", enabled: true)
      Budget.mark_exhausted(System.system_time(:second) + 3600)

      assert {:error, {:budget, reset}} = OpenAlex.search(Query.new("x"))
      assert is_integer(reset)
    end

    test "a daily-budget 429 marks the budget exhausted" do
      set_config(OpenAlex,
        api_key: "test-key",
        base_url: "https://stub.invalid",
        plug: {Req.Test, :oa_budget}
      )

      Req.Test.stub(:oa_budget, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("retry-after", "30")
        |> Plug.Conn.resp(429, Jason.encode!(%{"error" => "daily budget exhausted"}))
      end)

      assert {:error, {:budget, _}} = OpenAlex.search(Query.new("x"))
      assert Budget.status() == :exhausted
    end

    test "a per-second 429 becomes rate_limited (no budget state change)" do
      set_config(OpenAlex,
        api_key: "test-key",
        base_url: "https://stub.invalid",
        plug: {Req.Test, :oa_429}
      )

      Req.Test.stub(:oa_429, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("retry-after", "7")
        |> Plug.Conn.resp(429, Jason.encode!(%{"error" => "per-second rate limit"}))
      end)

      assert {:error, {:rate_limited, 7}} = OpenAlex.search(Query.new("x"))
      assert Budget.status() == :ok
    end

    test "search maps results over HTTP and sends a Bearer token" do
      set_config(OpenAlex,
        api_key: "test-key",
        enabled: true,
        base_url: "https://stub.invalid",
        plug: {Req.Test, :oa_ok}
      )

      parent = self()

      Req.Test.stub(:oa_ok, fn conn ->
        send(parent, {:auth, Plug.Conn.get_req_header(conn, "authorization")})
        assert conn.request_path == "/works"
        assert conn.query_string =~ "search=commons"
        Req.Test.json(conn, fixture!(@oa))
      end)

      assert {:ok, page} = OpenAlex.search(Query.new("commons", kind: :article))
      assert page.total == 91
      assert length(page.results) == 2
      assert_received {:auth, ["Bearer test-key"]}
    end

    test "more_url points at the OpenAlex website search" do
      assert OpenAlex.more_url("open access") =~ "openalex.org/works?search=open+access"
    end
  end

  describe "Budget" do
    test "poll parses /rate-limit and sets a healthy status" do
      set_config(OpenAlex,
        api_key: "test-key",
        base_url: "https://stub.invalid",
        plug: {Req.Test, :oa_limit}
      )

      Req.Test.stub(:oa_limit, fn conn ->
        assert conn.request_path == "/rate-limit"
        Req.Test.json(conn, fixture!(@oa_limit))
      end)

      # The budget poll runs inside the Budget GenServer; allow it to use the
      # test process's stub.
      Req.Test.allow(:oa_limit, self(), Process.whereis(Budget))

      Budget.poll_now()
      _ = :sys.get_state(Budget)

      assert Budget.status() == :ok
      assert Budget.remaining_fraction() > 0.8
      assert is_integer(Budget.resets_at())
    end

    test "parses the real nested rate_limit shape (2026)" do
      set_config(OpenAlex,
        api_key: "test-key",
        base_url: "https://stub.invalid",
        plug: {Req.Test, :oa_limit_live}
      )

      Req.Test.stub(:oa_limit_live, fn conn -> Req.Test.json(conn, fixture!(@oa_limit_live)) end)
      Req.Test.allow(:oa_limit_live, self(), Process.whereis(Budget))

      Budget.poll_now()
      _ = :sys.get_state(Budget)

      assert Budget.status() == :ok
      assert Budget.remaining_fraction() > 0.99

      assert Budget.resets_at() |> DateTime.from_unix!() |> DateTime.to_iso8601() ==
               "2026-11-25T00:00:00Z"
    end

    test "below 25% remaining is degraded; below 10% is exhausted" do
      set_config(OpenAlex,
        api_key: "test-key",
        base_url: "https://stub.invalid",
        plug: {Req.Test, :oa_low}
      )

      Req.Test.stub(:oa_low, fn conn ->
        Req.Test.json(conn, %{
          "daily_budget_usd" => 1.0,
          "daily_used_usd" => 0.80,
          "daily_remaining_usd" => 0.20
        })
      end)

      Req.Test.allow(:oa_low, self(), Process.whereis(Budget))

      Budget.poll_now()
      _ = :sys.get_state(Budget)
      assert Budget.status() == :degraded

      Req.Test.stub(:oa_low, fn conn ->
        Req.Test.json(conn, %{
          "daily_budget_usd" => 1.0,
          "daily_used_usd" => 0.95,
          "daily_remaining_usd" => 0.05
        })
      end)

      Budget.poll_now()
      _ = :sys.get_state(Budget)
      assert Budget.status() == :exhausted
    end

    test "an exhausted budget clears once its reset time passes" do
      Budget.mark_exhausted(System.system_time(:second) - 1)
      assert Budget.status() == :ok
    end

    test "OpenAlex refuses auto-firing in the all view while degraded" do
      set_config(OpenAlex, api_key: "test-key", enabled: true)

      Budget.mark_exhausted(System.system_time(:second) + 3600)
      refute OpenAlex.auto?()

      Budget.clear()
      assert OpenAlex.auto?()
    end
  end

  describe "Gutendex" do
    test "normalizes a book with formats and public-domain rights" do
      [book | _] = fixture!(@gutenberg)["results"]
      result = Gutendex.normalize(book)

      assert result.source == :gutendex
      assert result.source_id == "1342"
      assert result.url == "https://www.gutenberg.org/ebooks/1342"
      assert result.creators == ["Austen, Jane"]
      assert result.access == :open
      assert result.rights =~ "Domain publik"
      assert result.thumbnail_url =~ "pg1342.cover.jpg"
      assert result.read_url =~ "1342.html"
      assert result.languages == ["en"]
    end

    test "tolerates missing formats and ids" do
      result = Gutendex.normalize(Enum.at(fixture!(@gutenberg)["results"], 1))
      assert result.thumbnail_url == nil
      assert result.read_url == nil

      assert Gutendex.normalize(Enum.at(fixture!(@gutenberg)["results"], 2)) == nil
      assert Gutendex.normalize(nil) == nil
    end

    test "search requests the first page and takes at most 8" do
      set_config(Gutendex, base_url: "https://stub.invalid", plug: {Req.Test, :gut_ok})

      Req.Test.stub(:gut_ok, fn conn ->
        assert conn.request_path == "/books"
        assert conn.query_string =~ "search=pride"
        Req.Test.json(conn, fixture!(@gutenberg))
      end)

      assert {:ok, page} = Gutendex.search(Query.new("pride"))
      assert page.total == 2
      assert length(page.results) == 2
      assert page.more_url =~ "gutenberg.org/ebooks/search"
    end
  end

  describe "DOAB" do
    test "normalizes DSpace metadata lists" do
      [item | _] = fixture!(@doab)
      result = Doab.normalize(item)

      assert result.source == :doab
      assert result.title == "Southeast Asian Studies in the Digital Age"
      assert result.creators == ["Doe, Jane", "Santoso, Budi"]
      assert result.year == 2021
      assert result.access == :open
      assert result.description == "An open volume & survey."
      assert result.url == "https://directory.doabooks.org/handle/20.500.12854/12345"
      assert result.rights =~ "creativecommons.org/licenses/by/4.0"
      assert result.languages == ["en"]
      assert result.identifiers.handle == ["20.500.12854/12345"]
    end

    test "meta_values/2 reads repeated keys in order" do
      metadata = [
        %{"key" => "dc.contributor.author", "value" => "A"},
        %{"key" => "dc.title", "value" => "T"},
        %{"key" => "dc.contributor.author", "value" => "B"}
      ]

      assert Doab.meta_values(metadata, "dc.contributor.author") == ["A", "B"]
      assert Doab.meta_values(metadata, "dc.title") == ["T"]
      assert Doab.meta_values(metadata, "dc.missing") == []
      assert Doab.meta_values(nil, "dc.title") == []
    end

    test "items without a title are skipped; handle fallback builds a URL" do
      assert Doab.normalize(Enum.at(fixture!(@doab), 1)) == nil

      item = %{
        "uuid" => "u1",
        "handle" => "20.500.12854/9",
        "metadata" => [%{"key" => "dc.title", "value" => "No explicit URI"}]
      }

      result = Doab.normalize(item)
      assert result.url == "https://directory.doabooks.org/handle/20.500.12854/9"
    end

    test "search sends Accept: application/json and expands metadata" do
      set_config(Doab, base_url: "https://stub.invalid", plug: {Req.Test, :doab_ok})

      Req.Test.stub(:doab_ok, fn conn ->
        assert conn.request_path == "/rest/search"
        assert conn.query_string =~ "query=digital"
        assert conn.query_string =~ "expand=metadata"
        assert Plug.Conn.get_req_header(conn, "accept") == ["application/json"]
        Req.Test.json(conn, fixture!(@doab))
      end)

      assert {:ok, page} = Doab.search(Query.new("digital"))
      assert length(page.results) == 1
    end
  end

  describe "Router in the all view" do
    test "OpenAlex drops out when its budget is degraded, but stays for kind=article" do
      set_config(OpenAlex, api_key: "test-key", enabled: true)
      Budget.mark_exhausted(System.system_time(:second) + 3600)

      all_ids = Curatorian.Search.Federation.Router.providers_for(:all) |> Enum.map(& &1.id())

      article_ids =
        Curatorian.Search.Federation.Router.providers_for(:article) |> Enum.map(& &1.id())

      refute :open_alex in all_ids
      assert :open_alex in article_ids
    end
  end

  describe "Provider helpers (OpenAlex)" do
    test "decode_json tolerates invalid bodies" do
      assert {:error, :invalid_json} = Provider.decode_json("not json")
      assert {:ok, %{}} = Provider.decode_json("{}")
    end
  end
end
