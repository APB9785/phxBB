import Config

config :phx_bb, PhxBbWeb.Endpoint,
  server: true,
  url: [scheme: :https, host: System.get_env("APP_NAME") <> ".gigalixirapp.com", port: 443]

config :phx_bb, PhxBb.Mailer,
  adapter: Swoosh.Adapters.Mailjet,
  api_key: System.get_env("MAILJET_API_KEY"),
  secret: System.get_env("MAILJET_SECRET_KEY")
