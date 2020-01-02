# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :project, Project.Repo,
  database: "project_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432

config :project,
  ecto_repos: [Project.Repo]
config :logger, level: :info

# Configures the endpoint
config :project, ProjectWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "DP4pGuXXhf3bS93QuKstn+6D8GkVHAyHvClqlQIiRad+JihnsJDIIKw+viBsV1mN",
  render_errors: [view: ProjectWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Project.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
