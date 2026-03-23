defmodule Curatorian.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :curatorian

  def migrate do
    load_app()

    # Curatorian has no migrations — all tables are owned by Voile and Atrium
    # So we explicitly migrate Voile.Repo here
    voile_repos = Application.fetch_env!(:voile, :ecto_repos)

    for repo <- voile_repos do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp load_app do
    Application.load(@app)
  end

  def seed do
    load_app()

    Ecto.Migrator.with_repo(Curatorian.Repo, fn _repo ->
      # Also start Voile.Repo since seeds use it directly
      {:ok, _, _} =
        Ecto.Migrator.with_repo(Voile.Repo, fn _voile_repo ->
          seeds_path = Application.app_dir(@app, "priv/repo/seeds.exs")
          rbac_seeds_path = Application.app_dir(@app, "priv/repo/seeds_rbac.exs")

          if File.exists?(seeds_path) do
            IO.puts("Running seeds...")
            Code.eval_file(seeds_path)
          end

          if File.exists?(rbac_seeds_path) do
            IO.puts("Running RBAC seeds...")
            Code.eval_file(rbac_seeds_path)
          end
        end)
    end)
  end
end
