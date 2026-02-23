defmodule CuratorianUmbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: releases(),
      elixir: "~> 1.18",
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # ===== SHARED DEPENDENCIES =====
  # These are available to all child apps automatically
  defp deps do
    [
      # Core Phoenix & Web
      {:phoenix, "~> 1.8.1"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.1.22"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},

      # Database
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},

      # Server
      {:bandit, "~> 1.5"},
      {:dns_cluster, "~> 0.2.0"},

      # Assets
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},

      # Auth & Security
      {:pbkdf2_elixir, "~> 2.0"},
      {:assent, "~> 0.3.1"},

      # Utilities
      {:jason, "~> 1.2"},
      {:gettext, "~> 1.0"},
      {:finch, "~> 0.13"},
      {:hackney, "~> 1.18"},
      {:req, "~> 0.5"},
      {:swoosh, "~> 1.16"},
      {:tzdata, "~> 1.1"},
      {:html_sanitize_ex, "~> 1.4"},

      # AWS
      {:aws, "~> 1.0.0"},

      # Monitoring
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},

      # Testing
      {:floki, ">= 0.30.0", only: :test},

      # Voile-specific dependencies
      {:barlix, "~> 0.6.0"},
      {:ex_json_schema, "~> 0.11.2"},
      {:hammer, "~> 7.2"},
      {:myxql, "~> 0.8"},
      {:nimble_csv, "~> 1.2"},
      {:phoenix_swagger, "~> 0.8"},
      {:phoenix_turnstile, "~> 1.0"},
      {:lazy_html, ">= 0.1.8", only: :test}
    ]
  end

  defp aliases do
    [
      # ===== SETUP (Full initialization) =====
      setup: [
        "deps.get",
        # compile first so local Mix tasks (like `voile.assets`) are available
        "compile",
        # ensure Voile deps and build are prepared via Mix task (cross-platform)
        fn _ ->
          unless Code.ensure_loaded?(Mix.Tasks.Voile.Assets) do
            Code.compile_file("lib/mix/tasks/voile.assets.ex")
          end

          Mix.Tasks.Voile.Assets.run(["setup"])
        end,
        "ecto.setup",
        # ensure Curatorian migrations are applied explicitly
        "ecto.migrate -r Curatorian.Repo",
        "assets.setup",
        "assets.build"
      ],

      # ===== DATABASE OPERATIONS (Shared Database) =====
      # Since both repos use the same database (curatorian_dev),
      # we only create/drop ONCE, but run migrations for BOTH repos

      "ecto.setup": [
        # Create database once (using either repo)
        "ecto.create -r Curatorian.Repo",
        fn _ ->
          Mix.Task.run("app.config")
          {:ok, _} = Application.ensure_all_started(:postgrex)
          {:ok, _} = Application.ensure_all_started(:ecto_sql)
          {:ok, _} = Voile.Repo.start_link()
          Ecto.Adapters.SQL.query!(Voile.Repo, "CREATE SCHEMA IF NOT EXISTS voile", [])
          Ecto.Adapters.SQL.query!(Voile.Repo, "CREATE SCHEMA IF NOT EXISTS atrium", [])
          Ecto.Adapters.SQL.query!(Voile.Repo, "CREATE EXTENSION IF NOT EXISTS citext", [])
          Mix.shell().info("✓ schemas created: voile, atrium")
        end,

        # Run Voile migrations first (base tables like users)
        "ecto.migrate -r Voile.Repo",

        # Run Curatorian migrations second (references Voile tables)
        "ecto.migrate -r Curatorian.Repo",

        # Run seeds for both apps if present
        # Prefer running the centralized local seeds under Curatorian
        fn _ ->
          run_if_exists("apps/curatorian/priv/repo/seeds.exs")
        end,
        # RBAC seeds (kept separate)
        fn _ ->
          run_if_exists("apps/curatorian/priv/repo/seeds_rbac.exs")
        end
      ],
      "ecto.reset": [
        # Drop database once
        "ecto.drop -r Curatorian.Repo",

        # Run setup again
        "ecto.setup"
      ],
      "ecto.migrate": [
        # Run both migrations in order
        "ecto.migrate -r Voile.Repo",
        "ecto.migrate -r Curatorian.Repo"
      ],
      "ecto.rollback": [
        # Rollback in reverse order (Curatorian first, then Voile)
        "ecto.rollback -r Curatorian.Repo",
        "ecto.rollback -r Voile.Repo"
      ],

      # ===== ASSETS =====
      "assets.setup": [
        fn _ ->
          unless Code.ensure_loaded?(Mix.Tasks.Voile.Assets) do
            Code.compile_file("lib/mix/tasks/voile.assets.ex")
          end

          Mix.Tasks.Voile.Assets.run(["setup"])
        end,
        "do --app curatorian assets.setup"
      ],
      "assets.build": [
        fn _ ->
          unless Code.ensure_loaded?(Mix.Tasks.Voile.Assets) do
            Code.compile_file("lib/mix/tasks/voile.assets.ex")
          end

          Mix.Tasks.Voile.Assets.run(["build"])
        end,
        "do --app curatorian assets.build"
      ],
      "assets.deploy": [
        fn _ ->
          unless Code.ensure_loaded?(Mix.Tasks.Voile.Assets) do
            Code.compile_file("lib/mix/tasks/voile.assets.ex")
          end

          Mix.Tasks.Voile.Assets.run(["deploy"])
        end,
        "do --app curatorian assets.deploy"
      ],

      # ===== TESTING =====
      test: [
        # Create test database once
        "ecto.create -r Curatorian.Repo --quiet",

        # Run migrations for both repos
        "ecto.migrate -r Voile.Repo --quiet",
        "ecto.migrate -r Curatorian.Repo --quiet",

        # Run tests for both apps
        "do --app voile test",
        "do --app curatorian test"
      ],

      # ===== CODE QUALITY =====
      format: [
        "format",
        "do --app voile format",
        "do --app curatorian format"
      ],

      # ===== UTILITY COMMANDS =====

      # Check migration status
      "ecto.migrations": [
        "cmd echo '=== Voile Migrations ==='",
        "ecto.migrations -r Voile.Repo",
        "cmd echo ''",
        "cmd echo '=== Curatorian Migrations ==='",
        "ecto.migrations -r Curatorian.Repo"
      ],

      # Generate new migration (specify repo)
      # Usage: mix ecto.gen.migration -r Voile.Repo add_field_to_collections
      # Usage: mix ecto.gen.migration -r Curatorian.Repo add_field_to_events

      # Database console
      psql: ["mix do psql curatorian_dev"],

      # Prepare release: build assets then create release
      "release.prepare": [
        "assets.deploy",
        "release"
      ]
    ]
  end

  defp releases do
    [
      curatorian: [
        version: "0.1.0",
        applications: [
          voile: :permanent,
          curatorian: :permanent
        ],
        include_executables_for: [:unix],
        steps: [:assemble, :tar]
      ]
    ]
  end

  defp run_if_exists(rel_path) do
    path = Path.expand(rel_path, File.cwd!())

    if File.exists?(path) do
      Mix.shell().info("Running seed: #{path}")

      # Determine the app directory to run the seed in so the repo/app is started
      cond do
        String.starts_with?(rel_path, "deps/voile/") ->
          app_dir = "deps/voile"
          app_dir_expanded = Path.expand(app_dir, File.cwd!())
          script = Path.relative_to(path, app_dir_expanded)
          run_mix_in_dir(app_dir, ["run", script])

        String.starts_with?(rel_path, "apps/") ->
          # e.g. apps/curatorian/priv/...
          parts = String.split(rel_path, "/")
          app_dir = Enum.join(Enum.take(parts, 2), "/")
          app_dir_expanded = Path.expand(app_dir, File.cwd!())
          script = Path.relative_to(path, app_dir_expanded)
          run_mix_in_dir(app_dir, ["run", script])

        true ->
          # fallback: run the script with the root project's mix
          script = Path.relative_to(path, File.cwd!())
          run_mix_in_dir(File.cwd!(), ["run", script])
      end
    else
      Mix.shell().info("Skipping missing seed: #{path}")
    end
  end

  defp run_mix_in_dir(dir, args) do
    Mix.shell().info("mix -C #{dir} #{Enum.join(args, " ")}")

    try do
      # If we're running a seed script (args like ["run", script]),
      # attempt to detect any Repo modules referenced in the script and
      # start only those repos before requiring the file. This avoids
      # starting the full application (and endpoint) which can fail when
      # phoenix_live_reload or similar dev-only modules aren't available.
      case args do
        ["run", script] ->
          seed_path = Path.join(dir, script)

          repos =
            if File.exists?(seed_path) do
              {:ok, content} = File.read(seed_path)

              Regex.scan(~r/[A-Z][A-Za-z0-9_.]+Repo/, content)
              |> List.flatten()
              |> Enum.uniq()
            else
              []
            end

          # If no repos were detected in the seed file but we're running
          # a seed inside an `apps/...` directory, assume the app's Repo
          # (e.g. `Curatorian.Repo`) so we can start that alone and avoid
          # starting other apps/endpoints.
          repos =
            if repos == [] and String.starts_with?(dir, "apps/") do
              app_atom = dir |> String.split("/") |> List.last() |> Macro.camelize()
              ["#{app_atom}.Repo"]
            else
              repos
            end

          if repos == [] do
            {out, status} = System.cmd("mix", args, cd: dir, stderr_to_stdout: true)

            if status == 0 do
              Mix.shell().info(out)
            else
              Mix.shell().error("Command failed in #{dir}: #{out}")
            end
          else
            # Build an Elixir one-liner that starts each detected Repo and
            # then requires the seed script. Use --no-start so Mix doesn't
            # start the whole application (which would start endpoints).
            repos_lit = inspect(repos)
            # Ensure core apps needed by Ecto/Postgres are started, then start
            # the detected repos and require the seed file.
            one_liner =
              "apps = [:logger, :telemetry, :db_connection, :postgrex, :ecto_sql]; Enum.each(apps, &Application.ensure_all_started/1); repos = #{repos_lit}; Enum.each(repos, fn r -> repo = r |> String.split(\".\") |> Enum.map(&String.to_atom/1) |> Module.concat(); try do; repo.start_link(); rescue _ -> :ok end end); Code.require_file(\"#{script}\")"

            {out, status} =
              System.cmd("mix", ["run", "--no-start", "-e", one_liner],
                cd: dir,
                stderr_to_stdout: true
              )

            if status == 0 do
              Mix.shell().info(out)
            else
              Mix.shell().error("Seeds failed in #{dir}: #{out}")
            end
          end

        _ ->
          {out, status} = System.cmd("mix", args, cd: dir, stderr_to_stdout: true)

          if status == 0 do
            Mix.shell().info(out)
          else
            Mix.shell().error("Command failed in #{dir}: #{out}")
          end
      end
    rescue
      e -> Mix.shell().error("Failed to run mix in #{dir}: #{inspect(e)}")
    end
  end
end
