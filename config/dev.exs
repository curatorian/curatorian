import Config

# ===== SHARED DATABASE CONFIGURATION =====
# Both Voile and Curatorian use the SAME database

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

# Voile Repo - points to shared database
config :voile, Voile.Repo, shared_db_config

# Curatorian Repo - points to SAME database
config :curatorian, Curatorian.Repo, shared_db_config

# MySQL/MariaDB source (for SLiMS migration)
config :voile, :mysql_source,
  hostname: "localhost",
  port: 3306,
  username: "root",
  password: "",
  database: "slims_gold"

# ===== OAUTH CONFIGURATION =====
config :assent,
  google: [
    client_id: System.get_env("VOILE_GOOGLE_CLIENT_ID"),
    client_secret: System.get_env("VOILE_GOOGLE_CLIENT_SECRET"),
    redirect_uri: System.get_env("VOILE_GOOGLE_REDIRECT_URI")
  ]

# ===== VOILE ENDPOINT (Port 4001) =====
config :voile, VoileWeb.Endpoint,
  http: [
    ip: {0, 0, 0, 0},
    port: String.to_integer(System.get_env("VOILE_PORT") || "4001")
  ],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "8yUfAjPlnRwlXp8kQaME2eoN8nXCApsGmofKKaAMoeKsThy5ZHE2XTKdE1fKjH9c",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:voile, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:voile, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"apps/voile/priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"apps/voile/priv/gettext/.*(po)$",
      ~r"apps/voile/lib/voile_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$"
    ]
  ]

# ===== CURATORIAN ENDPOINT (Port 4000) =====
config :curatorian, CuratorianWeb.Endpoint,
  http: [
    ip: {0, 0, 0, 0},
    port: String.to_integer(System.get_env("CURATORIAN_PORT") || "4000")
  ],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "curatorian_secret_key_base_change_me_in_production",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:curatorian, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:curatorian, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"apps/curatorian/priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"apps/curatorian/priv/gettext/.*(po)$",
      ~r"apps/curatorian/lib/curatorian_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# ===== DEVELOPMENT ROUTES =====
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

# ===== SWOOSH (Email) =====
config :swoosh, :api_client, false

# Use Gmail API adapter in development if requested
if System.get_env("VOILE_MAILER_ADAPTER") == "gmail_api" do
  config :voile, Voile.Mailer,
    adapter: Voile.Mailer.GmailApiAdapter,
    access_token: System.get_env("VOILE_GMAIL_ACCESS_TOKEN"),
    refresh_token: System.get_env("VOILE_GMAIL_REFRESH_TOKEN"),
    client_id: System.get_env("VOILE_GMAIL_CLIENT_ID"),
    client_secret: System.get_env("VOILE_GMAIL_CLIENT_SECRET"),
    redirect_uri: System.get_env("VOILE_GMAIL_REDIRECT_URI")
end

# Disable email queue in development
config :voile, :disable_email_queue, false

# ===== XENDIT (Payment Gateway - Development) =====
config :voile,
  xendit_api_key:
    System.get_env("VOILE_XENDIT_API_KEY") || "xnd_development_REPLACE_WITH_YOUR_KEY",
  xendit_webhook_token: System.get_env("VOILE_XENDIT_WEBHOOK_TOKEN") || "REPLACE_WITH_YOUR_TOKEN"
