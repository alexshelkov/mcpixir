defmodule Mcpixir.Connectors.Base do
  @moduledoc """
  Base behaviour for MCP connectors.
  """

  @type connector() :: %{
          :__struct__ => atom(),
          :initialized => boolean(),
          :url => String.t(),
          :timeout => integer(),
          optional(:client_pid) => pid(),
          optional(:response_table) => atom() | :ets.tid(),
          optional(atom()) => any()
        }

  @type response() :: %{required(String.t()) => any()}

  @callback initialize(connector()) :: {:ok, connector()} | {:error, any()}
  @callback get_tools(connector()) :: {:ok, list()} | {:error, any()}
  @callback execute_tool(connector(), String.t(), map()) :: {:ok, any()} | {:error, any()}
  @callback close(connector()) :: :ok | {:error, any()}

  @doc """
  Common initialization function for connectors.
  """
  @spec initialize(connector()) :: {:ok, connector()} | {:error, any()}
  def initialize(connector) do
    request = %{
      "jsonrpc" => "2.0",
      "method" => "mcp.initialize",
      "params" => %{},
      "id" => generate_id()
    }

    case do_request(connector, request) do
      {:ok, _response} ->
        updated_connector = Map.put(connector, :initialized, true)
        {:ok, updated_connector}

      error ->
        error
    end
  end

  @doc """
  Common function to get tools.
  """
  @spec get_tools(connector()) :: {:ok, list()} | {:error, any()}
  def get_tools(connector) do
    request = %{
      "jsonrpc" => "2.0",
      "method" => "mcp.get_tools",
      "params" => %{},
      "id" => generate_id()
    }

    case do_request(connector, request) do
      {:ok, %{"result" => %{"tools" => tools}}} ->
        {:ok, tools}

      error ->
        error
    end
  end

  @doc """
  Common function to execute a tool.
  """
  @spec execute_tool(connector(), String.t(), map()) :: {:ok, any()} | {:error, any()}
  def execute_tool(connector, tool_name, args) do
    request = %{
      "jsonrpc" => "2.0",
      "method" => "mcp.execute_tool",
      "params" => %{
        "name" => tool_name,
        "args" => args
      },
      "id" => generate_id()
    }

    case do_request(connector, request) do
      {:ok, %{"result" => result}} ->
        {:ok, result}

      error ->
        error
    end
  end

  @doc """
  Common function to close the connection.
  """
  @spec close(connector()) :: :ok | {:error, any()}
  def close(_connector) do
    :ok
  end

  # Function to be implemented by specific connectors
  @doc false
  @spec do_request(connector(), map()) :: {:ok, response()} | {:error, any()}
  def do_request(_connector, _request) do
    raise "Not implemented"
  end

  # Helper function to generate request IDs
  defp generate_id do
    System.unique_integer([:positive])
  end
end
