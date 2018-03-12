# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :slacker_frontend,
  namespace: SlackerFrontend

# Configures the endpoint
config :slacker_frontend, SlackerFrontendWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Nya8lWIjkIDovFYUi6NuyuM8a2qKRAz5zk3wT5UCaXAA8VdHzEgiFGL5TOod1ik+",
  render_errors: [view: SlackerFrontendWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: SlackerFrontend.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
