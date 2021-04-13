# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :phx_bb,
  ecto_repos: [PhxBb.Repo]

# Configures the endpoint
config :phx_bb, PhxBbWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "tWkuIkgLQd0MXN5ee6iII4MxRgSBw9fWEsIHzakf0Ij7vdZRtbo2uwWXhQby7GeS",
  render_errors: [view: PhxBbWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PhxBb.PubSub,
  live_view: [signing_salt: "g9+cVWC1"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configures Swoosh email adapter
config :phx_bb, PhxBb.Mailer,
  adapter: Swoosh.Adapters.Mailjet,
  api_key: {:system, "MAILJET_API_KEY"},
  secret: {:system, "MAILJET_SECRET_KEY"}

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Globally configure Elixir to use Tzdata
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
