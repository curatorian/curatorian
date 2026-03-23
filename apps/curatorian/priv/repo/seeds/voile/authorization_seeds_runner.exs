## Runner script to execute authorization seeds during mix run
## This keeps the implementation module separate (.ex) while providing a script
## that Mix can execute (mix run <file>). It will load the module and call run/0.

# In releases, use :code.priv_dir to find the correct path
seed_path =
  if Code.ensure_loaded?(Mix) do
    # Development/test - use relative path from apps/curatorian
    "priv/repo/seeds/voile/authorization_seeds.ex"
  else
    # Production release - search common locations inside the app's priv dir.
    base = Path.join([:code.priv_dir(:voile), "repo", "seeds"])

    candidates = [
      Path.join([base, "voile", "authorization_seeds.ex"]),
      Path.join([base, "authorization_seeds.ex"])
    ]

    Enum.find(candidates, fn p -> File.exists?(p) end) ||
      raise "could not find authorization_seeds.ex in release priv dir; looked in: #{inspect(candidates)}"
  end

Code.require_file(seed_path)

Voile.Repo.Seeds.AuthorizationSeeds.run()
