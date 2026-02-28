# config/dev.exs
import Config

# ===== SHARED DATABASE CONFIGURATION =====
# Both Voile and Curatorian connect to the same PostgreSQL database.
# Schema separation is enforced via search_path set in config.exs after_connect.
#
# Schema layout:
#   voile  schema → all Voile tables (users, nodes, collections, items, etc.)
#   atrium schema → all Atrium tables (subscriptions, user_profiles, webinars, etc.)
#   public schema → intentionally empty

shared_db_config = [
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  hostname: System.get_env("POSTGRES_HOSTNAME") || "localhost",
  database: System.get_env("POSTGRES_DB") || "curatorian_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  parameters: [timezone: "Asia/Jakarta"]
]

# after_connect is already set per-repo in config.exs with the correct search_path.
# These dev configs only add connection details — they merge, not replace.
config :voile, Voile.Repo, shared_db_config
config :curatorian, Curatorian.Repo, shared_db_config

# ===== CURATORIAN ENDPOINT (Port 4000) =====
config :curatorian, CuratorianWeb.Endpoint,
  http: [
    ip: {0, 0, 0, 0},
    port: String.to_integer(System.get_env("CURATORIAN_PORT") || "4000")
  ],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base:
    System.get_env("SECRET_KEY") ||
      "12k0ay7dKO77HRbDn/DDbNv/DHkMuIN5MMGViVNpTntKTh5lDGZWdZJwGWG/JM5x",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:curatorian, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:curatorian, ~w(--watch --quiet)]}
  ],
  live_reload: [
    patterns: [
      ~r"apps/curatorian/priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"apps/curatorian/priv/gettext/.*(po)$",
      ~r"apps/curatorian/lib/curatorian_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Voile web server is disabled — Voile runs as a compiled library dep only.
# Curatorian (4000) is the public frontend. Atrium (4001) is the private dashboard.
config :voile, VoileWeb.Endpoint, server: false

# ===== OAUTH =====
config :assent,
  google: [
    client_id: System.get_env("VOILE_GOOGLE_CLIENT_ID"),
    client_secret: System.get_env("VOILE_GOOGLE_CLIENT_SECRET"),
    redirect_uri: System.get_env("VOILE_GOOGLE_REDIRECT_URI")
  ]

# ===== DEVELOPMENT FLAGS =====
config :voile, dev_routes: true
config :curatorian, dev_routes: true

# ===== LOGGER =====
config :logger, :console, format: "[$level] $message\n"

# ===== PHOENIX =====
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true,
  enable_expensive_runtime_checks: true

# ===== MAILER =====
config :swoosh, :api_client, false
config :voile, Voile.Mailer, adapter: Swoosh.Adapters.Local
config :curatorian, Curatorian.Mailer, adapter: Swoosh.Adapters.Local

config :voile, :disable_email_queue, false

# ===== MYSQL (SLiMS Migration Source) =====
config :voile, :mysql_source,
  hostname: "localhost",
  port: 3306,
  username: "root",
  password: "",
  database: "slims_gold"

# ===== XENDIT (Development) =====
config :voile,
  xendit_api_key:
    System.get_env("VOILE_XENDIT_API_KEY") || "xnd_development_REPLACE_WITH_YOUR_KEY",
  xendit_webhook_token: System.get_env("VOILE_XENDIT_WEBHOOK_TOKEN") || "REPLACE_WITH_YOUR_TOKEN"
