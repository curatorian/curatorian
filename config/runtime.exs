# config/runtime.exs
import Config

if System.get_env("PHX_SERVER") do
  # Only Curatorian serves public traffic.
  # Voile is a compiled library dep — its web server stays off in all environments.
  config :curatorian, CuratorianWeb.Endpoint, server: true
end

if config_env() == :prod do
  # ===== PRODUCTION DATABASE =====
  # Both Voile.Repo and Curatorian.Repo connect to the same database.
  # Schema separation is handled via search_path set in config.exs after_connect:
  #   Voile.Repo      → search_path: voile,public
  #   Curatorian.Repo → search_path: voile,atrium,public

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      Example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  shared_prod_db_config = [
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5"),
    socket_options: maybe_ipv6,
    parameters: [timezone: "Asia/Jakarta", search_path: "voile,public"]
  ]

  config :voile, Voile.Repo, shared_prod_db_config
  config :curatorian, Curatorian.Repo, shared_prod_db_config

  # ===== TZDATA =====
  # Write timezone updates to a persistent writable dir outside the release.
  # Without this, tzdata tries to write to the read-only release dir and
  # spams the logs with permission errors every few minutes.
  config :tzdata, :data_dir, System.get_env("TZDATA_DATA_DIR") || "/opt/curatorian/shared/tzdata"

  # ===== SECRET KEYS =====
  # CROSS-APP TOKEN AUTH:
  # Curatorian signs Phoenix.Token sessions using CURATORIAN_SECRET_KEY.
  # Atrium verifies those tokens using its own SECRET_KEY_BASE.
  # CURATORIAN_SECRET_KEY and Atrium's SECRET_KEY_BASE MUST be identical.
  # Rotate both simultaneously — rotating one breaks all active sessions.

  voile_secret_key_base =
    System.get_env("VOILE_SECRET_KEY") ||
      raise "environment variable VOILE_SECRET_KEY is missing. Run: mix phx.gen.secret"

  curatorian_secret_key_base =
    System.get_env("CURATORIAN_SECRET_KEY") ||
      raise """
      environment variable CURATORIAN_SECRET_KEY is missing. Run: mix phx.gen.secret
      NOTE: This value must match SECRET_KEY_BASE in Atrium for cross-app token auth.
      """

  # ===== VOILE ENDPOINT =====
  # Voile's web server is DISABLED (server: false in config.exs).
  # URL config here is only for generating correct links in emails and LiveView.
  # curatorian.id is correct — that's where Voile content is served publicly.

  config :voile, VoileWeb.Endpoint,
    url: [host: "curatorian.id", port: 443, scheme: "https"],
    secret_key_base: voile_secret_key_base

  # ===== CURATORIAN ENDPOINT =====
  curatorian_host = System.get_env("CURATORIAN_HOST") || "curatorian.id"
  curatorian_port = String.to_integer(System.get_env("CURATORIAN_PORT") || "4000")

  config :curatorian, CuratorianWeb.Endpoint,
    url: [host: curatorian_host, port: 443, scheme: "https"],
    http: [
      # Bind to localhost only — Caddy handles public traffic via reverse proxy.
      # Do NOT use {0,0,0,0} (all interfaces) on the Pi.
      ip: {127, 0, 0, 1},
      port: curatorian_port
    ],
    check_origin: [
      "//localhost:#{curatorian_port}",
      "//127.0.0.1:#{curatorian_port}",
      "https://#{curatorian_host}",
      "https://#{curatorian_host}."
    ],
    secret_key_base: curatorian_secret_key_base

  config :voile, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  # ===== CAPTCHA =====
  # Turnstile keys are required in production.
  # Get them from: Cloudflare Dashboard → Turnstile → Add Site
  # For local testing without Cloudflare, use the always-passes test key:
  #   VOILE_TURNSTILE_SITE_KEY=1x00000000000000000000AA
  #   VOILE_TURNSTILE_SECRET_KEY=1x0000000000000000000000000000000AA
  config :phoenix_turnstile,
    site_key:
      System.get_env("VOILE_TURNSTILE_SITE_KEY") ||
        raise("VOILE_TURNSTILE_SITE_KEY is missing"),
    secret_key:
      System.get_env("VOILE_TURNSTILE_SECRET_KEY") ||
        raise("VOILE_TURNSTILE_SECRET_KEY is missing")

  # ===== MAILER =====
  # Set VOILE_MAILER_ADAPTER to: smtp | mailgun | sendgrid | gmail_api
  # Default is smtp.
  #
  # Gmail SMTP: use an App Password, not your regular Gmail password.
  # Generate one at: myaccount.google.com → Security → App Passwords
  #
  # Required .env vars for smtp (default):
  #   VOILE_SMTP_RELAY=smtp.gmail.com
  #   VOILE_SMTP_PORT=587
  #   VOILE_SMTP_USERNAME=your@gmail.com
  #   VOILE_SMTP_PASSWORD=your_app_password

  case System.get_env("VOILE_MAILER_ADAPTER") || "smtp" do
    "gmail_api" ->
      config :voile, Voile.Mailer,
        adapter: Voile.Mailer.GmailApiAdapter,
        access_token: System.get_env("VOILE_GMAIL_ACCESS_TOKEN"),
        refresh_token: System.get_env("VOILE_GMAIL_REFRESH_TOKEN"),
        client_id: System.get_env("VOILE_GMAIL_CLIENT_ID"),
        client_secret: System.get_env("VOILE_GMAIL_CLIENT_SECRET"),
        redirect_uri: System.get_env("VOILE_GMAIL_REDIRECT_URI")

    "mailgun" ->
      config :voile, Voile.Mailer,
        adapter: Swoosh.Adapters.Mailgun,
        api_key: System.get_env("VOILE_MAILGUN_API_KEY"),
        domain: System.get_env("VOILE_MAILGUN_DOMAIN")

      config :swoosh, :api_client, Swoosh.ApiClient.Finch

    "sendgrid" ->
      config :voile, Voile.Mailer,
        adapter: Swoosh.Adapters.Sendgrid,
        api_key: System.get_env("VOILE_SENDGRID_API_KEY")

      config :swoosh, :api_client, Swoosh.ApiClient.Finch

    _ ->
      # Default: SMTP
      config :voile, Voile.Mailer,
        adapter: Swoosh.Adapters.SMTP,
        relay: System.get_env("VOILE_SMTP_RELAY") || "smtp.gmail.com",
        port: String.to_integer(System.get_env("VOILE_SMTP_PORT") || "587"),
        username: System.get_env("VOILE_SMTP_USERNAME"),
        password: System.get_env("VOILE_SMTP_PASSWORD"),
        ssl: System.get_env("VOILE_SMTP_SSL") == "true",
        tls: :if_available,
        auth: :always,
        retries: 3,
        no_mx_lookups: false
  end

  # ===== S3 STORAGE =====
  # Optional — only activated if S3 credentials are present.
  # Falls back to local file storage if not set.
  if System.get_env("VOILE_S3_ACCESS_KEY_ID") do
    config :voile,
      storage_adapter: Client.Storage.S3,
      s3_access_key_id: System.get_env("VOILE_S3_ACCESS_KEY_ID"),
      s3_secret_key_access: System.get_env("VOILE_S3_SECRET_ACCESS_KEY"),
      s3_bucket_name: System.get_env("VOILE_S3_BUCKET_NAME") || "voile-storage",
      s3_region: System.get_env("VOILE_S3_REGION") || "us-east-1",
      s3_public_url: System.get_env("VOILE_S3_PUBLIC_URL") || "https://aws.s3.amazonaws.com",
      s3_public_url_format:
        System.get_env("VOILE_S3_PUBLIC_URL_FORMAT") || "{endpoint}/{bucket}/{key}"
  else
    config :voile, storage_adapter: Client.Storage.Local
  end

  # ===== OAUTH =====
  config :assent,
    google: [
      client_id: System.get_env("VOILE_GOOGLE_CLIENT_ID"),
      client_secret: System.get_env("VOILE_GOOGLE_CLIENT_SECRET"),
      redirect_uri: System.get_env("VOILE_GOOGLE_REDIRECT_URI")
    ]
end
