import Config

# ===== VOILE PRODUCTION =====
config :voile, VoileWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

# ===== CURATORIAN PRODUCTION =====
config :curatorian, CuratorianWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

# ===== SWOOSH (Email) =====
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Voile.Finch
config :swoosh, local: false

# ===== LOGGER =====
config :logger, level: :info

# ===== EMAIL QUEUE =====
config :voile, disable_email_queue: false

# Gmail SMTP setup instructions:
# To use Gmail SMTP, set these environment variables:
# VOILE_MAILER_ADAPTER=smtp
# VOILE_SMTP_RELAY=smtp.gmail.com
# VOILE_SMTP_PORT=587
# VOILE_SMTP_USERNAME=your_gmail_address@gmail.com
# VOILE_SMTP_PASSWORD=your_gmail_app_password
# VOILE_SMTP_SSL=false
#
# You must use an App Password for Gmail (not your regular password).
# See: https://support.google.com/accounts/answer/185833
