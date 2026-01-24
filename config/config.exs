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

# Configure Hammer rate limiter
config :hammer,
  backend: {:my_hammer_backend, []}

# Configures Voile endpoint
config :voile, VoileWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: VoileWeb.ErrorHTML, json: VoileWeb.ErrorJSON],
    layout: {VoileWeb.Layouts, :root}
  ],
  pubsub_server: Voile.PubSub,
  live_view: [signing_salt: "q1X5qNFK"]

# Configures the mailer for Voile
config :voile, Voile.Mailer, adapter: Swoosh.Adapters.Local

# Configure Upload Directory for Attachments
config :voile,
  attachment_upload_dir: "apps/voile/priv/static/uploads/attachments",
  # 100MB
  attachment_max_file_size: 100 * 1024 * 1024,
  attachment_allowed_file_types: [
    # Images
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
    "image/svg+xml",
    # Documents
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "text/plain",
    "text/csv",
    # Videos
    "video/mp4",
    "video/quicktime",
    "video/x-msvideo",
    # Audio
    "audio/mpeg",
    "audio/wav",
    "audio/ogg",
    # Archives
    "application/zip",
    "application/x-rar-compressed",
    "application/x-7z-compressed",
    # Software
    "application/octet-stream",
    "application/x-executable"
  ]

# S3 Storage Configuration
config :voile,
  s3_region: System.get_env("VOILE_S3_REGION") || "us-east-1",
  s3_access_key_id: System.get_env("VOILE_S3_ACCESS_KEY_ID"),
  s3_secret_key_access: System.get_env("VOILE_S3_SECRET_ACCESS_KEY"),
  s3_bucket_name: System.get_env("VOILE_S3_BUCKET_NAME") || "glam-storage",
  s3_public_url: System.get_env("VOILE_S3_PUBLIC_URL") || "https://library.unpad.ac.id",
  s3_public_url_format:
    System.get_env("VOILE_S3_PUBLIC_URL_FORMAT") || "{endpoint}/{bucket}/{key}"

# Automatically select storage adapter based on configuration
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

# Xendit Payment Gateway Configuration
config :voile,
  xendit_api_key: System.get_env("VOILE_XENDIT_API_KEY"),
  xendit_webhook_token: System.get_env("VOILE_XENDIT_WEBHOOK_TOKEN")

# Loan Reminder Configuration
loan_reminder_days =
  case System.get_env("VOILE_LOAN_REMINDER_DAYS") do
    nil -> [3, 1]
    days -> days |> String.split(",") |> Enum.map(&(&1 |> String.trim() |> String.to_integer()))
  end

loan_reminder_interval =
  case System.get_env("VOILE_LOAN_REMINDER_INTERVAL") do
    nil -> 24 * 60 * 60 * 1000
    interval -> String.to_integer(interval)
  end

email_queue_delay =
  case System.get_env("VOILE_EMAIL_QUEUE_DELAY") do
    nil -> 2000
    delay -> String.to_integer(delay)
  end

email_queue_max_retries =
  case System.get_env("VOILE_EMAIL_QUEUE_MAX_RETRIES") do
    nil -> 3
    retries -> String.to_integer(retries)
  end

config :voile,
  loan_reminder_days: loan_reminder_days,
  loan_reminder_interval: loan_reminder_interval,
  email_queue_delay: email_queue_delay,
  email_queue_max_retries: email_queue_max_retries

# ===== CURATORIAN (Community Portal) CONFIGURATION =====

config :curatorian,
  ecto_repos: [Curatorian.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures Curatorian endpoint
config :curatorian, CuratorianWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: CuratorianWeb.ErrorHTML, json: CuratorianWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Curatorian.PubSub,
  live_view: [signing_salt: "curatorian_salt_change_me"]

# Configures the mailer for Curatorian
config :curatorian, Curatorian.Mailer, adapter: Swoosh.Adapters.Local

# Configure uploader for Trix
config :curatorian,
  uploader: CuratorianWeb.Utils.Uploader,
  storage_adapter: Clients.Storage.Local

config :curatorian, CuratorianWeb.Gettext,
  locales: ~w(id en),
  default_locale: "id"

# ===== SHARED CONFIGURATION =====

# Configure esbuild for both apps
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

# Configure tailwind for both apps
config :tailwind,
  version: "4.1.7",
  voile: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("../apps/voile", __DIR__)
  ],
  curatorian: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("../apps/curatorian", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Assent Configuration (OAuth)
config :assent, http_adapter: {Assent.HTTPAdapter.Finch, supervisor: Voile.Finch}

# Configure Phoenix Swagger (Voile API documentation)
config :voile, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [
      router: VoileWeb.Router,
      endpoint: VoileWeb.Endpoint
    ]
  }

config :phoenix_swagger, json_library: Jason

# Import environment specific config
import_config "#{config_env()}.exs"
