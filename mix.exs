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
      {:phoenix_live_view, "~> 1.1.0"},
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
      {:gettext, "~> 0.26"},
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
      {:floki, ">= 0.30.0", only: :test}
    ]
  end

  defp aliases do
    [
      # ===== SETUP (Full initialization) =====
      setup: [
        "deps.get",
        "ecto.setup",
        "assets.setup",
        "assets.build"
      ],

      # ===== DATABASE OPERATIONS (Shared Database) =====
      # Since both repos use the same database (curatorian_dev),
      # we only create/drop ONCE, but run migrations for BOTH repos

      "ecto.setup": [
        # Create database once (using either repo)
        "ecto.create -r Curatorian.Repo",

        # Run Voile migrations first (base tables like users)
        "ecto.migrate -r Voile.Repo",

        # Run Curatorian migrations second (references Voile tables)
        "ecto.migrate -r Curatorian.Repo",

        # Run seeds for both apps
        "run apps/voile/priv/repo/seeds/seeds.exs",
        "run apps/voile/priv/repo/seeds/metadata_resource_class.exs",
        "run apps/voile/priv/repo/seeds/authorization_seeds_runner.exs",
        "run apps/voile/priv/repo/seeds/metadata_properties.exs",
        "run apps/voile/priv/repo/seeds/master.exs",
        "run apps/curatorian/priv/repo/seeds.exs",
        "run apps/curatorian/priv/repo/seeds_rbac.exs"
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
        "do --app voile assets.setup",
        "do --app curatorian assets.setup"
      ],
      "assets.build": [
        "do --app voile assets.build",
        "do --app curatorian assets.build"
      ],
      "assets.deploy": [
        "do --app voile assets.deploy",
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
        "echo '=== Voile Migrations ==='",
        "ecto.migrations -r Voile.Repo",
        "echo ''",
        "echo '=== Curatorian Migrations ==='",
        "ecto.migrations -r Curatorian.Repo"
      ],

      # Generate new migration (specify repo)
      # Usage: mix ecto.gen.migration -r Voile.Repo add_field_to_collections
      # Usage: mix ecto.gen.migration -r Curatorian.Repo add_field_to_events

      # Database console
      psql: ["mix do psql curatorian_dev"]
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
end
