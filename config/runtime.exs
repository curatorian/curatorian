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
  #   Voile.Repo     → search_path: voile,public
  #   Curatorian.Repo → search_path: voile,atrium,public
  # Do NOT add after_connect here — it is already set in config.exs and will merge.

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      Example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  shared_prod_db_config = [
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    parameters: [timezone: "Asia/Jakarta"]
  ]

  config :voile, Voile.Repo, shared_prod_db_config
  config :curatorian, Curatorian.Repo, shared_prod_db_config

  # ===== SECRET KEYS =====
  # IMPORTANT — CROSS-APP TOKEN AUTH:
  # Curatorian signs Phoenix.Token sessions using CURATORIAN_SECRET_KEY.
  # Atrium (port 4001, separate app) verifies those tokens using its own SECRET_KEY_BASE.
  # These TWO values MUST be identical for cross-app auth to work.
  # Rotate both Curatorian and Atrium simultaneously — rotating one breaks all active sessions.
  #
  # Do NOT fall back to VOILE_SECRET_KEY for Curatorian — they serve different purposes
  # and Voile's key must remain independent.

  voile_secret_key_base =
    System.get_env("VOILE_SECRET_KEY") ||
      raise "environment variable VOILE_SECRET_KEY is missing. Run: mix phx.gen.secret"

  curatorian_secret_key_base =
    System.get_env("CURATORIAN_SECRET_KEY") ||
      raise """
      environment variable CURATORIAN_SECRET_KEY is missing. Run: mix phx.gen.secret
      NOTE: This value must match SECRET_KEY_BASE in the Atrium app for cross-app token auth.
      """

  # ===== VOILE ENDPOINT =====
  # Voile's web server is disabled (server: false set in config.exs).
  # We still set the secret_key_base so Voile can sign internal tokens if needed.
  voile_host = System.get_env("VOILE_HOST") || "glam.example.com"

  config :voile, VoileWeb.Endpoint,
    url: [host: voile_host, port: 443, scheme: "https"],
    secret_key_base: voile_secret_key_base

  # ===== CURATORIAN ENDPOINT =====
  curatorian_host = System.get_env("CURATORIAN_HOST") || "curatorian.id"
  curatorian_port = String.to_integer(System.get_env("CURATORIAN_PORT") || "4000")

  config :curatorian, CuratorianWeb.Endpoint,
    url: [host: curatorian_host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: curatorian_port
    ],
    check_origin: [
      "//localhost:4000",
      "//127.0.0.1:4000",
      "https://#{curatorian_host}",
      "https://#{curatorian_host}."
    ],
    secret_key_base: curatorian_secret_key_base

  config :voile, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  # ===== CAPTCHA =====
  config :phoenix_turnstile,
    site_key: System.fetch_env!("VOILE_TURNSTILE_SITE_KEY"),
    secret_key: System.fetch_env!("VOILE_TURNSTILE_SECRET_KEY")

  # ===== MAILER =====
  # Set VOILE_MAILER_ADAPTER to: smtp | mailgun | sendgrid | gmail_api
  # Default is smtp. See comments below for each option.
  #
  # Gmail SMTP: use an App Password, not your regular password.
  # VOILE_MAILER_ADAPTER=smtp
  # VOILE_SMTP_RELAY=smtp.gmail.com
  # VOILE_SMTP_PORT=587
  # VOILE_SMTP_USERNAME=your@gmail.com
  # VOILE_SMTP_PASSWORD=your_app_password
  # VOILE_SMTP_SSL=false

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
