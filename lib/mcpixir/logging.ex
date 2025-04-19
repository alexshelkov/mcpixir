defmodule Mcpixir.Logging do
  @moduledoc """
  Logging functionality for MCP.
  """

  require Logger

  @log_levels [:debug, :info, :warning, :error]

  @doc """
  Sets the log level.
  """
  def set_level(level) when level in @log_levels do
    Logger.configure(level: level)
  end

  def set_level(level) do
    Logger.error("Invalid log level: #{level}. Must be one of #{inspect(@log_levels)}")
  end

  @doc """
  Logs a debug message.
  """
  def debug(message, metadata \\ []) do
    Logger.debug(message, metadata)
  end

  @doc """
  Logs an info message.
  """
  def info(message, metadata \\ []) do
    Logger.info(message, metadata)
  end

  @doc """
  Logs a warning message.
  """
  def warning(message, metadata \\ []) do
    Logger.warning(message, metadata)
  end

  @doc """
  Logs an error message.
  """
  def error(message, metadata \\ []) do
    Logger.error(message, metadata)
  end

  @doc """
  Logs a message with the specified level.
  """
  def log(level, message, metadata \\ []) when level in @log_levels do
    Logger.log(level, message, metadata)
  end

  @doc """
  Creates a logger middleware for use with connectors.
  """
  def create_middleware(config) do
    fn request, next ->
      log_level = Map.get(config, :log_level, :info)

      # Log the request
      log(log_level, "MCP request: #{inspect(request)}", type: :request)

      # Call the next middleware
      result = next.(request)

      # Log the response
      case result do
        {:ok, response} ->
          log(log_level, "MCP response: #{inspect(response)}", type: :response)

        {:error, error} ->
          log(:error, "MCP error: #{inspect(error)}", type: :error)
      end

      # Return the result unchanged
      result
    end
  end
end
