defmodule Curatorian.Release do
  @moduledoc """
  Tasks for running DB operations in production without Mix.
  Curatorian has no migrations of its own.
  All tables live in the voile schema, owned by Voile.Repo.
  """

  @app :curatorian

  def migrate do
    load_app()

    # Curatorian.Repo has no migrations (no priv/repo/migrations)
    # All schema is owned by Voile — migrate Voile.Repo instead
    {:ok, _, _} =
      Ecto.Migrator.with_repo(
        Voile.Repo,
        &Ecto.Migrator.run(&1, :up, all: true)
      )

    IO.puts("Migrations complete.")
  end

  def rollback(version) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(
        Voile.Repo,
        &Ecto.Migrator.run(&1, :down, to: version)
      )
  end

  def seed do
    load_app()

    Ecto.Migrator.with_repo(Curatorian.Repo, fn _repo ->
      Ecto.Migrator.with_repo(Voile.Repo, fn _voile_repo ->
        seeds_dir = Application.app_dir(:curatorian, "priv/repo/seeds/voile")

        [
          "seeds.exs",
          "authorization_seeds_runner.exs",
          "master.exs",
          "metadata_resource_class.exs",
          "metadata_properties.exs",
          "seeds_rbac.exs"
        ]
        |> Enum.each(fn file ->
          path = Path.join(seeds_dir, file)

          if File.exists?(path) do
            IO.puts("Seeding: #{file}")
            Code.eval_file(path)
          else
            IO.puts("Skipping (not found): #{file}")
          end
        end)
      end)
    end)
  end

  defp load_app do
    Application.load(@app)
    Application.load(:voile)
  end
end
