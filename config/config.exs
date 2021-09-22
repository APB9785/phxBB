# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :phx_bb,
  ecto_repos: [PhxBb.Repo]

# Configures the endpoint
config :phx_bb, PhxBbWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Ya0iLhgtj+Al3D5TOEsEkBPGm0Bl504/O38L6afKOK4LxGY6agZEU5nB7o9KQQHN",
  render_errors: [view: PhxBbWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PhxBb.PubSub,
  live_view: [signing_salt: "3zoTdm5d"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :phx_bb, PhxBb.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configures the timezone database
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# AWS config
config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
  region: {:system, "AWS_REGION"}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
