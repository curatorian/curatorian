# config/config.exs
import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# ===== VOILE (GLAM System) CONFIGURATION =====

config :voile, :scopes,
  user: [
    default: true,
    module: Voile.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Voile.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :voile,
  ecto_repos: [Voile.Repo],
  generators: [timestamp_type: :utc_datetime]

# Voile Repo always searches the voile schema
# All Voile tables (users, nodes, collections, items, etc.) live in the voile schema
config :voile, Voile.Repo,
  after_connect: {Postgrex, :query!, ["SET search_path TO voile,public", []]}

# Configures Voile endpoint
# server: false — Voile is not a public-facing server in the Curatorian deployment.
# Curatorian (port 4000) is the public frontend. Atrium (port 4001) is the private
# management dashboard. Voile runs only as a compiled library dep.
config :voile, VoileWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: VoileWeb.ErrorHTML, json: VoileWeb.ErrorJSON],
    layout: {VoileWeb.Layouts, :root}
  ],
  pubsub_server: Voile.PubSub,
  live_view: [signing_salt: "q1X5qNFK"],
  server: false

config :voile, Voile.Mailer, adapter: Swoosh.Adapters.Local

config :voile,
  attachment_upload_dir: "apps/voile/priv/static/uploads/attachments",
  attachment_max_file_size: 100 * 1024 * 1024,
  attachment_allowed_file_types: [
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
    "image/svg+xml",
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "text/plain",
    "text/csv",
    "video/mp4",
    "video/quicktime",
    "video/x-msvideo",
    "audio/mpeg",
    "audio/wav",
    "audio/ogg",
    "application/zip",
    "application/x-rar-compressed",
    "application/x-7z-compressed",
    "application/octet-stream",
    "application/x-executable"
  ]

config :voile,
  s3_region: System.get_env("VOILE_S3_REGION") || "us-east-1",
  s3_access_key_id: System.get_env("VOILE_S3_ACCESS_KEY_ID"),
  s3_secret_key_access: System.get_env("VOILE_S3_SECRET_ACCESS_KEY"),
  s3_bucket_name: System.get_env("VOILE_S3_BUCKET_NAME") || "glam-storage",
  s3_public_url: System.get_env("VOILE_S3_PUBLIC_URL") || "https://library.unpad.ac.id",
  s3_public_url_format:
    System.get_env("VOILE_S3_PUBLIC_URL_FORMAT") || "{endpoint}/{bucket}/{key}"

s3_adapter =
  if System.get_env("VOILE_S3_ACCESS_KEY_ID") && System.get_env("VOILE_S3_SECRET_ACCESS_KEY") do
    Client.Storage.S3
  else
    Client.Storage.Local
  end

config :voile, storage_adapter: s3_adapter

config :voile, VoileWeb.Gettext,
  locales: ~w(id en),
  default_locale: "id"

config :voile,
  xendit_api_key: System.get_env("VOILE_XENDIT_API_KEY"),
  xendit_webhook_token: System.get_env("VOILE_XENDIT_WEBHOOK_TOKEN")

config :hammer, backend: {:my_hammer_backend, []}

# ===== CURATORIAN (Community Portal) CONFIGURATION =====

config :curatorian,
  ecto_repos: [Curatorian.Repo],
  generators: [timestamp_type: :utc_datetime]

config :curatorian, :env, config_env()

# Curatorian Repo searches voile schema first (Voile tables), then atrium (Atrium tables).
# Curatorian has no migrations of its own — it only reads from voile and atrium schemas.
# Write operations to atrium tables go through Atrium (port 4001), not Curatorian.
config :curatorian, Curatorian.Repo,
  after_connect: {Postgrex, :query!, ["SET search_path TO voile,atrium,public", []]}

config :curatorian, CuratorianWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: CuratorianWeb.ErrorHTML, json: CuratorianWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Curatorian.PubSub,
  live_view: [signing_salt: System.get_env("CURATORIAN_LIVE_VIEW_SIGNING_SALT") || "default_salt"]

config :curatorian, Curatorian.Mailer, adapter: Swoosh.Adapters.Local

config :curatorian,
  uploader: CuratorianWeb.Utils.Uploader,
  storage_adapter: Clients.Storage.Local

config :curatorian, CuratorianWeb.Gettext,
  locales: ~w(id en),
  default_locale: "id"

# ===== SHARED CONFIGURATION =====

config :esbuild,
  version: "0.25.4",
  voile: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../apps/voile/assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ],
  curatorian: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/curatorian/assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

config :tailwind,
  version: "4.1.7",
  voile: [
    args: ~w(--input=assets/css/app.css --output=priv/static/assets/css/app.css),
    cd: Path.expand("../apps/voile", __DIR__)
  ],
  curatorian: [
    args: ~w(--input=assets/css/app.css --output=priv/static/assets/css/app.css),
    cd: Path.expand("../apps/curatorian", __DIR__)
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :assent, http_adapter: {Assent.HTTPAdapter.Finch, supervisor: Voile.Finch}

config :voile, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [
      router: VoileWeb.Router,
      endpoint: VoileWeb.Endpoint
    ]
  }

config :phoenix_swagger, json_library: Jason

import_config "#{config_env()}.exs"
