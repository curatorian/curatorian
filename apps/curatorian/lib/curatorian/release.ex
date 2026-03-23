defmodule Curatorian.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :curatorian

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end

  def seed do
    load_app()

    # Run the seeds script if it exists
    seeds_path = Application.app_dir(@app, "priv/repo/seeds.exs")
    rbac_seeds_path = Application.app_dir(@app, "priv/repo/seeds_rbac.exs")

    if File.exists?(seeds_path) and File.exists?(rbac_seeds_path) do
      Code.eval_file(seeds_path)
      Code.eval_file(rbac_seeds_path)
    else
      IO.puts("No seeds file found at #{seeds_path}")
    end
  end
end
