defmodule Mcpixir.Session do
  @moduledoc """
  Manages connections to MCP implementations.
  """

  alias Mcpixir.Connectors.HttpConnector
  alias Mcpixir.Connectors.StdioConnector
  alias Mcpixir.Connectors.WebSocketConnector

  @type t :: %__MODULE__{
          id: String.t(),
          server_url: String.t(),
          connector: Mcpixir.Connectors.Base.connector(),
          tools: [map()]
        }

  defstruct [
    :id,
    :server_url,
    :connector,
    tools: []
  ]

  @doc """
  Starts a new session with the given server URL and configuration.
  """
  def start(server_url, config, session_id) do
    with {:ok, connector} <- create_connector(server_url, config),
         {:ok, connector} <- initialize_connection(connector),
         {:ok, tools} <- discover_tools(connector) do
      session = %__MODULE__{
        id: session_id,
        server_url: server_url,
        connector: connector,
        tools: tools
      }

      {:ok, session}
    end
  end

  @doc """
  Gets all available tools for the session.
  """
  def get_tools(session) do
    session.tools
  end

  @doc """
  Executes a tool call.
  """
  def execute_tool(session, tool_name, args) do
    session.connector.execute_tool(tool_name, args)
  end

  @doc """
  Stops the session.
  """
  def stop(session) do
    session.connector.close()
  end

  # Private functions

  defp create_connector(server_url, config) do
    cond do
      String.starts_with?(server_url, "http") ->
        HttpConnector.new(server_url, config)

      String.starts_with?(server_url, "ws") ->
        WebSocketConnector.new(server_url, config)

      String.starts_with?(server_url, "stdio:") ->
        command = String.replace_prefix(server_url, "stdio:", "")
        StdioConnector.new(command, config)

      true ->
        {:error, "Unsupported URL scheme: #{server_url}"}
    end
  end

  defp initialize_connection(connector) do
    case connector.__struct__.initialize(connector) do
      {:ok, updated_connector} -> {:ok, updated_connector}
      error -> error
    end
  end

  defp discover_tools(connector) do
    case connector.get_tools() do
      {:ok, tools} -> {:ok, tools}
      error -> error
    end
  end
end
