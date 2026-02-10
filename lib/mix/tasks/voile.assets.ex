defmodule Mix.Tasks.Voile.Assets do
  use Mix.Task

  @shortdoc "Run Voile asset tasks (setup/build/deploy) with NODE_PATH set to phoenix-colocated"

  @moduledoc """
  Usage:
    mix voile.assets         # run setup + build (dev)
    mix voile.assets setup   # run deps.get + assets.setup
    mix voile.assets build   # run assets.build
    mix voile.assets deploy  # run assets.deploy (uses prod build path)
  """

  @impl Mix.Task
  def run(args) do
    Mix.start()

    case args do
      ["setup"] -> ensure_deps(); ensure_compile(); run_task("assets.setup", Mix.env())
      ["build"] -> ensure_compile(); run_task("assets.build", Mix.env())
      ["deploy"] -> ensure_compile(); run_task("assets.deploy", :prod)
      _ -> ensure_deps(); ensure_compile(); run_task("assets.setup", Mix.env()); run_task("assets.build", Mix.env())
    end

    :ok
  end

  defp ensure_deps do
    Mix.shell().info("Fetching deps for deps/voile (best-effort)")
    try do
      System.cmd("mix", ["deps.get"], cd: "deps/voile", into: IO.stream(:stdio, :line), stderr_to_stdout: true)
    rescue
      _ -> Mix.shell().info("Warning: fetching deps for deps/voile failed — continuing")
    end
  end

  defp ensure_compile do
    Mix.shell().info("Compiling umbrella to populate phoenix-colocated (if needed)")
    Mix.Task.reenable("compile")
    Mix.Task.run("compile")
  end

  defp run_task(task, env) do
    node_path = node_path_for(env)
    Mix.shell().info("Running deps/voile #{task} with NODE_PATH=#{node_path}")

    try do
      System.cmd("mix", [task], cd: "deps/voile", env: [{"NODE_PATH", node_path}], into: IO.stream(:stdio, :line), stderr_to_stdout: true)
    rescue
      _ -> Mix.shell().info("Warning: deps/voile #{task} failed — continuing")
    end
  end

  defp node_path_for(env) when env in [:dev, :test, :prod] do
    build_root = Path.dirname(Mix.Project.build_path())
    Path.join([build_root, to_string(env), "phoenix-colocated"])
  end

  defp node_path_for(_), do: Path.join([Mix.Project.build_path(), "phoenix-colocated"])
end
