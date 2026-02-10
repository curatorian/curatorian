#!/usr/bin/env elixir
# Mirror Voile seeds into Curatorian by evaluating a transformed copy
# Replaces references to `Voile.Repo` with `Curatorian.Repo` and runs
# each seed file from its original directory so relative requires still work.

Application.ensure_all_started(:logger)
Application.ensure_all_started(:postgrex)
Application.ensure_all_started(:ecto_sql)

IO.puts("Running mirrored Voile seeds into Curatorian.Repo (curatorian_dev)")

# Ensure Curatorian.Repo is started
case Application.ensure_all_started(:curatorian) do
  {:ok, _} -> :ok
  _ -> Application.ensure_all_started(:curatorian)
end

case Curatorian.Repo.start_link() do
  {:ok, _} -> :ok
  {:error, {:already_started, _pid}} -> :ok
  other -> IO.inspect(other, label: "Curatorian.Repo.start_link")
end

seeds = Path.wildcard(Path.join([File.cwd!(), "deps", "voile", "priv", "repo", "seeds", "*.exs"]))

if seeds == [] do
  IO.puts("No Voile seed files found at deps/voile/priv/repo/seeds")
  System.halt(0)
end

Enum.each(seeds, fn seed_path ->
  IO.puts("--- processing #{seed_path}")

  content = File.read!(seed_path)

  transformed =
    content
    |> String.replace("Voile.Repo", "Curatorian.Repo")
    |> String.replace("alias Voile.Repo", "alias Curatorian.Repo")

  seed_dir = Path.dirname(seed_path)

  # Evaluate transformed seed from the seed file's directory so relative requires resolve
  File.cd!(seed_dir, fn ->
    try do
      {_res, _binding} = Code.eval_string(transformed, [], file: seed_path)
      IO.puts("OK: evaluated #{Path.basename(seed_path)}")
    rescue
      e ->
        IO.puts("ERROR evaluating #{Path.basename(seed_path)}: #{inspect(e)}")
        IO.puts(Exception.format(:error, e, __STACKTRACE__))
    end
  end)
end)

IO.puts("Mirrored seed run completed")
