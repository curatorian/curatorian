defmodule Curatorian.MixProject do
  use Mix.Project

  def project do
    [
      app: :curatorian,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
      # REMOVED: compilers, listeners, dialyzer (not needed here)
    ]
  end

  def application do
    [
      mod: {Curatorian.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # ===== UMBRELLA DEPENDENCY =====
      {:voile, in_umbrella: true}

      # ALL OTHER DEPENDENCIES ARE NOW IN UMBRELLA ROOT!
      # No need to duplicate Phoenix, Ecto, etc.
      # They're inherited from the parent umbrella app
    ]
  end

  defp aliases do
    [
      setup: [
        "deps.get",
        "ecto.setup",
        "assets.setup",
        "assets.build",
        "run priv/repo/seeds_rbac.exs"
      ],
      "ecto.setup": [
        "ecto.create",
        "ecto.migrate",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing"
      ],
      "assets.build": ["tailwind curatorian", "esbuild curatorian"],
      "assets.deploy": [
        "tailwind curatorian --minify",
        "esbuild curatorian --minify",
        "phx.digest"
      ]
    ]
  end
end
