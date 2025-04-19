defmodule Mcpixir.Connectors.HttpConnector do
  @moduledoc """
  HTTP connector for MCP.
  """

  @behaviour Mcpixir.Connectors.Base

  alias Mcpixir.Connectors.Base

  @type t :: %__MODULE__{
          url: String.t(),
          headers: [{String.t(), String.t()}],
          timeout: integer(),
          client_pid: pid(),
          response_table: atom() | :ets.tid(),
          initialized: boolean()
        }

  defstruct [
    :url,
    :headers,
    :timeout,
    :client_pid,
    :response_table,
    initialized: false
  ]

  @doc """
  Creates a new HTTP connector.
  """
  def new(url, config) do
    timeout = get_in(config, [:timeout]) || 30_000
    headers = [{"Content-Type", "application/json"}]
    response_table = :ets.new(:http_responses, [:set, :private])

    connector = %__MODULE__{
      url: url,
      headers: headers,
      timeout: timeout,
      response_table: response_table
    }

    {:ok, connector}
  end

  @impl Mcpixir.Connectors.Base
  @spec initialize(Mcpixir.Connectors.Base.connector()) ::
          {:ok, Mcpixir.Connectors.Base.connector()} | {:error, any()}
  def initialize(connector) do
    Base.initialize(connector)
  end

  @impl Mcpixir.Connectors.Base
  @spec get_tools(Mcpixir.Connectors.Base.connector()) :: {:ok, list()} | {:error, any()}
  def get_tools(connector) do
    Base.get_tools(connector)
  end

  @impl Mcpixir.Connectors.Base
  @spec execute_tool(Mcpixir.Connectors.Base.connector(), String.t(), map()) ::
          {:ok, any()} | {:error, any()}
  def execute_tool(connector, tool_name, args) do
    Base.execute_tool(connector, tool_name, args)
  end

  @impl Mcpixir.Connectors.Base
  @spec close(Mcpixir.Connectors.Base.connector()) :: :ok | {:error, any()}
  def close(connector) do
    Base.close(connector)
  end

  @doc false
  def do_request(connector, request) do
    json_request = Jason.encode!(request)

    case HTTPoison.post(connector.url, json_request, connector.headers,
           timeout: connector.timeout,
           recv_timeout: connector.timeout
         ) do
      {:ok, %HTTPoison.Response{status_code: code, body: body}} when code in 200..299 ->
        parse_response_body(body)

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "HTTP error: #{code}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Helper to parse response body and handle error/success cases
  defp parse_response_body(body) do
    case Jason.decode(body) do
      {:ok, response} ->
        if Map.has_key?(response, "error") do
          {:error, response["error"]}
        else
          {:ok, response}
        end

      error ->
        error
    end
  end
end
