ExUnit.start(exclude: [:external])

# Both repos share one database and must both be sandboxed (see
# Curatorian.DataCase.setup_sandbox/1) — Voile.Repo too, because the
# Accounts context writes voile identity tables.
Ecto.Adapters.SQL.Sandbox.mode(Curatorian.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Voile.Repo, :manual)
