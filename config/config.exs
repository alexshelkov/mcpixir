import Config

config :mcpixir,
  log_level: :info,
  default_servers: [],
  # Add this line to capture the environment
  environment: config_env()

# Import environment specific config
import_config "#{config_env()}.exs"
