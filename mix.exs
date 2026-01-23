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
      # Use consistent Elixir version across all apps
      elixir: "~> 1.18",
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
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
      # Setup everything
      setup: [
        "deps.get",
        "cmd --app voile mix ecto.setup",
        "cmd --app curatorian mix ecto.setup",
        "cmd --app voile mix assets.setup",
        "cmd --app curatorian mix assets.setup",
        "cmd --app voile mix assets.build",
        "cmd --app curatorian mix assets.build"
      ],

      # Database operations
      "ecto.setup": [
        "cmd --app voile mix ecto.setup",
        "cmd --app curatorian mix ecto.setup"
      ],
      "ecto.reset": [
        "cmd --app voile mix ecto.reset",
        "cmd --app curatorian mix ecto.reset"
      ],
      "ecto.migrate": [
        "cmd --app voile mix ecto.migrate",
        "cmd --app curatorian mix ecto.migrate"
      ],

      # Testing
      test: [
        "cmd --app voile mix test",
        "cmd --app curatorian mix test"
      ],

      # Code quality
      format: [
        "format",
        "cmd --app voile mix format",
        "cmd --app curatorian mix format"
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
end
