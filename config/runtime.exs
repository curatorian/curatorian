import Config

# Runtime configuration for releases
if System.get_env("PHX_SERVER") do
  config :voile, VoileWeb.Endpoint, server: true
  config :curatorian, CuratorianWeb.Endpoint, server: true
end

if config_env() == :prod do
  # ===== VOILE DATABASE =====
  voile_database_url =
    System.get_env("VOILE_DATABASE_URL") ||
      System.get_env("DATABASE_URL") ||
      raise """
      environment variable VOILE_DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :voile, Voile.Repo,
    url: voile_database_url,
    pool_size: String.to_integer(System.get_env("VOILE_POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    parameters: [timezone: "Asia/Jakarta"]

  # ===== CURATORIAN DATABASE =====
  # Option 1: Separate database URL (recommended for production)
  curatorian_database_url =
    System.get_env("CURATORIAN_DATABASE_URL") ||
      System.get_env("VOILE_DATABASE_URL") ||
      System.get_env("DATABASE_URL") ||
      raise """
      environment variable CURATORIAN_DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :curatorian, Curatorian.Repo,
    url: curatorian_database_url,
    pool_size: String.to_integer(System.get_env("CURATORIAN_POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    parameters: [timezone: "Asia/Jakarta"]

  # ===== SECRET KEYS =====
  voile_secret_key_base =
    System.get_env("VOILE_SECRET_KEY") ||
      raise """
      environment variable VOILE_SECRET_KEY is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  curatorian_secret_key_base =
    System.get_env("CURATORIAN_SECRET_KEY") ||
      System.get_env("VOILE_SECRET_KEY") ||
      raise """
      environment variable CURATORIAN_SECRET_KEY is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  # ===== HOSTS & PORTS =====
  voile_host = System.get_env("VOILE_HOST") || "glam.example.com"
  voile_port = String.to_integer(System.get_env("VOILE_PORT") || "4001")

  curatorian_host = System.get_env("CURATORIAN_HOST") || "curatorian.id"
  curatorian_port = String.to_integer(System.get_env("CURATORIAN_PORT") || "4000")

  config :voile, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  # ===== VOILE ENDPOINT =====
  config :voile, VoileWeb.Endpoint,
    url: [host: voile_host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: voile_port
    ],
    check_origin: [
      "//localhost:4001",
      "//127.0.0.1:4001",
      "https://#{voile_host}",
      "https://#{voile_host}."
    ],
    secret_key_base: voile_secret_key_base

  # ===== CURATORIAN ENDPOINT =====
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

  # ===== TURNSTILE (CAPTCHA) =====
  config :phoenix_turnstile,
    site_key: System.fetch_env!("VOILE_TURNSTILE_SITE_KEY"),
    secret_key: System.fetch_env!("VOILE_TURNSTILE_SECRET_KEY")

  # ===== MAILER CONFIGURATION =====
  mailer_adapter = System.get_env("VOILE_MAILER_ADAPTER") || "smtp"

  case mailer_adapter do
    "gmail_api" ->
      config :voile, Voile.Mailer,
        adapter: Voile.Mailer.GmailApiAdapter,
        access_token: System.get_env("VOILE_GMAIL_ACCESS_TOKEN"),
        refresh_token: System.get_env("VOILE_GMAIL_REFRESH_TOKEN"),
        client_id: System.get_env("VOILE_GMAIL_CLIENT_ID"),
        client_secret: System.get_env("VOILE_GMAIL_CLIENT_SECRET"),
        redirect_uri: System.get_env("VOILE_GMAIL_REDIRECT_URI")

    "smtp" ->
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
      config :voile, Voile.Mailer, adapter: Swoosh.Adapters.Local
  end

  # ===== S3 STORAGE =====
  if System.get_env("VOILE_S3_ACCESS_KEY_ID") do
    config :voile,
      storage_adapter: Client.Storage.S3,
      s3_access_key_id: System.get_env("VOILE_S3_ACCESS_KEY_ID"),
      s3_secret_key_access: System.get_env("VOILE_S3_SECRET_ACCESS_KEY"),
      s3_bucket_name: System.get_env("VOILE_S3_BUCKET_NAME") || "glam-storage",
      s3_region: System.get_env("VOILE_S3_REGION") || "us-east-1",
      s3_public_url: System.get_env("VOILE_S3_PUBLIC_URL") || "https://library.unpad.ac.id",
      s3_public_url_format:
        System.get_env("VOILE_S3_PUBLIC_URL_FORMAT") || "{endpoint}/{bucket}/{key}"
  else
    config :voile, storage_adapter: Client.Storage.Local
  end

  # ===== OAUTH (Assent) =====
  config :assent,
    google: [
      client_id: System.get_env("VOILE_GOOGLE_CLIENT_ID"),
      client_secret: System.get_env("VOILE_GOOGLE_CLIENT_SECRET"),
      redirect_uri: System.get_env("VOILE_GOOGLE_REDIRECT_URI")
    ]
end
