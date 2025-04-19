import Config

config :mcpixir,
  log_level: :info,
  default_servers: [],
  environment: config_env()  # Add this line to capture the environment

# Import environment specific config
import_config "#{config_env()}.exs"
