# config/test.exs
import Config

config :pbkdf2_elixir, :rounds, 1

# ===== SHARED TEST DATABASE =====
# Both Voile and Curatorian use the same test database.
# Schema separation via search_path is set in config.exs after_connect and merges here.
# Database name matches the shared database convention (not voile_test).

shared_test_db_config = [
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "curatorian_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  # Two repos share this config, so the real ceiling is 2x this number. Cap it
  # to stay well clear of Postgres max_connections when dev servers are also
  # running (schedulers*2 on a many-core box exhausted the pool).
  pool_size: min(System.schedulers_online() * 2, 8),
  parameters: [timezone: "Asia/Jakarta"]
]

config :voile, Voile.Repo, shared_test_db_config
config :curatorian, Curatorian.Repo, shared_test_db_config

# ===== VOILE ENDPOINT (Test) =====
# Voile web server stays off — only used as a library dep.
config :voile, VoileWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "2/aZPJmpGl6yC+8+OHpTMBa75cJFJ8G1Vy8i/Bov0APu72GsqrU6672t/sdOkfe1",
  server: false

# ===== CURATORIAN ENDPOINT (Test) =====
config :curatorian, CuratorianWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4003],
  secret_key_base: "curatorian_test_secret_key_base_must_be_at_least_64_bytes_long_padding",
  server: false

# ===== MAILER =====
config :voile, Voile.Mailer, adapter: Swoosh.Adapters.Test
config :curatorian, Curatorian.Mailer, adapter: Swoosh.Adapters.Test

# Captcha is browser-supplied; tests can't produce real Turnstile tokens, so
# both login and registration flows skip verification in the test env
# (see verify_turnstile/2 seams in UserSessionController and RegisterLive).
config :curatorian, disable_turnstile: true
config :swoosh, :api_client, false

# ===== LOGGER =====
config :logger, level: :warning

# ===== PHOENIX =====
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  enable_expensive_runtime_checks: true
