# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# This file centralizes other seed scripts so umbrella aliases
# can simply run this single entrypoint. Individual seed files
# are kept under `priv/repo/seeds/voile/`.

# Hint to the umbrella runner: ensure these repos are started when
# running this seed file via `mix run` detection (used by run_if_exists)
# Repos: Voile.Repo Curatorian.Repo

# List of relative seed scripts to load (relative to this file)
seed_files = [
  "seeds/voile/seeds.exs",
  # Run FIRST to create roles before master.exs assigns them
  "seeds/voile/authorization_seeds_runner.exs",
  "seeds/voile/master.exs",
  "seeds/voile/metadata_resource_class.exs",
  "seeds/voile/metadata_properties.exs",
  "seeds/voile/glams.exs",
  "seeds/voile/authorization_seeds_runner.exs",
  "seeds/voile/pustakawan.exs",
  # application-level RBAC seeds (optional)
  "seeds_rbac.exs"
]

Enum.each(seed_files, fn rel ->
  path = Path.join(__DIR__, rel)

  if File.exists?(path) do
    Mix.shell().info("Running seed: #{path}")
    Code.require_file(path)
  else
    Mix.shell().info("Skipping missing seed: #{path}")
  end
end)
