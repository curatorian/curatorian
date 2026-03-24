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
        # Seeds are bundled inside the voile dep in the release
        seeds_path =
          Application.app_dir(:voile, "priv/repo/seeds/seeds.exs")

        if File.exists?(seeds_path) do
          IO.puts("Running seeds from: #{seeds_path}")
          Code.eval_file(seeds_path)
          IO.puts("Seeds complete.")
        else
          IO.puts("No seeds file found at: #{seeds_path}")
        end
      end)
    end)
  end

  defp load_app do
    Application.load(@app)
    Application.load(:voile)
  end
end
