defmodule Mcpixir.Connectors.WebSocketConnector do
  @moduledoc """
  WebSocket connector for MCP.
  """

  @behaviour Mcpixir.Connectors.Base

  alias Mcpixir.Connectors.Base

  use WebSockex

  @type t :: %__MODULE__{
          url: String.t(),
          timeout: integer(),
          client_pid: pid(),
          response_table: atom() | :ets.tid(),
          initialized: boolean()
        }

  defstruct [
    :url,
    :timeout,
    :client_pid,
    :response_table,
    initialized: false
  ]

  @doc """
  Creates a new WebSocket connector.
  """
  def new(url, config) do
    timeout = get_in(config, [:timeout]) || 30_000
    response_table = :ets.new(:websocket_responses, [:set, :private])

    case WebSockex.start_link(url, __MODULE__, %{response_table: response_table}) do
      {:ok, client_pid} ->
        connector = %__MODULE__{
          url: url,
          timeout: timeout,
          client_pid: client_pid,
          response_table: response_table
        }

        {:ok, connector}

      error ->
        error
    end
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
    case connector do
      %{client_pid: pid, response_table: table}
      when is_pid(pid) and (is_atom(table) or is_reference(table)) ->
        WebSockex.cast(pid, :terminate)
        :ets.delete(table)

      _ ->
        nil
    end

    :ok
  end

  # WebSockex callbacks

  @impl WebSockex
  def handle_connect(_conn, state) do
    {:ok, state}
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, response} ->
        if Map.has_key?(response, "id") do
          :ets.insert(state.response_table, {response["id"], response})
        end

        {:ok, state}

      _error ->
        {:ok, state}
    end
  end

  @impl WebSockex
  def handle_disconnect(_conn, state) do
    {:reconnect, state}
  end

  # Base implementation

  @doc false
  @spec do_request(t(), map()) :: {:ok, map()} | {:error, any()}
  def do_request(connector, request) do
    id = request["id"]

    case WebSockex.send_frame(connector.client_pid, {:text, Jason.encode!(request)}) do
      :ok ->
        wait_for_response(connector, id)

      error ->
        error
    end
  end

  defp wait_for_response(connector, id, attempts \\ 0) do
    if attempts * 100 > connector.timeout do
      {:error, :timeout}
    else
      case :ets.lookup(connector.response_table, id) do
        [{^id, response}] ->
          handle_websocket_response(connector, id, response)

        [] ->
          Process.sleep(100)
          wait_for_response(connector, id, attempts + 1)
      end
    end
  end

  defp handle_websocket_response(connector, id, response) do
    :ets.delete(connector.response_table, id)

    if Map.has_key?(response, "error") do
      {:error, response["error"]}
    else
      {:ok, response}
    end
  end
end
