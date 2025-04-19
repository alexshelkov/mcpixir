defmodule Mcpixir.Connectors.StdioConnector do
  @moduledoc """
  Stdio connector for MCP.
  """

  @behaviour Mcpixir.Connectors.Base

  alias Mcpixir.Connectors.Base

  @type t :: %__MODULE__{
          command: String.t(),
          timeout: integer(),
          port: port(),
          response_buffer: String.t(),
          response_handlers: %{String.t() => {pid(), reference()}},
          initialized: boolean()
        }

  defstruct [
    :command,
    :timeout,
    :port,
    :response_buffer,
    response_handlers: %{},
    initialized: false
  ]

  @doc """
  Creates a new stdio connector.
  """
  def new(command, config) do
    timeout = get_in(config, [:timeout]) || 30_000
    port = Port.open({:spawn, command}, [:binary, :exit_status, {:line, 2048}])

    connector = %__MODULE__{
      command: command,
      timeout: timeout,
      port: port,
      response_buffer: ""
    }

    # Start the message receiver process
    spawn_link(fn -> process_messages(connector) end)

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
    case connector do
      %{port: port} when is_port(port) -> Port.close(port)
      _ -> nil
    end

    :ok
  end

  @doc false
  def do_request(connector, request) do
    id = request["id"]
    json_request = Jason.encode!(request) <> "\n"

    response_pid = self()
    reference = make_ref()

    updated_handlers = Map.put(connector.response_handlers, id, {response_pid, reference})
    _updated_connector = %{connector | response_handlers: updated_handlers}

    Port.command(connector.port, json_request)

    receive do
      {^reference, response} ->
        {:ok, response}
    after
      connector.timeout ->
        {:error, :timeout}
    end
  end

  # Private functions

  defp process_messages(connector) do
    receive do
      {port, {:data, line}} when port == connector.port ->
        try_parse_response(line, connector)
        process_messages(connector)

      {port, {:exit_status, status}} when port == connector.port ->
        exit({:port_exited, status})

      _other ->
        process_messages(connector)
    end
  end

  defp try_parse_response(line, connector) do
    with {:ok, response} <- Jason.decode(line),
         true <- Map.has_key?(response, "id"),
         id = response["id"],
         {pid, reference} <- Map.get(connector.response_handlers, id, :not_found) do
      send(pid, {reference, response})
      Map.delete(connector.response_handlers, id)
    else
      _ -> :ok
    end
  end
end
