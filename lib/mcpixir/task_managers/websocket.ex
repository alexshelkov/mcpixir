defmodule Mcpixir.TaskManagers.WebSocketManager do
  @moduledoc """
  Task manager that sends events over WebSocket.
  """

  @behaviour Mcpixir.TaskManagers.Base

  use WebSockex

  @type t :: %__MODULE__{
          url: String.t(),
          client_pid: pid() | nil,
          config: map()
        }

  defstruct [
    :url,
    :client_pid,
    :config
  ]

  @impl Mcpixir.TaskManagers.Base
  def new(config) do
    url = Map.get(config, :url)

    if url == nil do
      {:error, "WebSocket URL not provided"}
    else
      {:ok, %__MODULE__{url: url, config: config}}
    end
  end

  @impl Mcpixir.TaskManagers.Base
  def start(manager) do
    case WebSockex.start_link(manager.url, __MODULE__, manager) do
      {:ok, client_pid} ->
        {:ok, %{manager | client_pid: client_pid}}

      error ->
        error
    end
  end

  @impl Mcpixir.TaskManagers.Base
  def stop(manager) do
    if manager.client_pid do
      WebSockex.cast(manager.client_pid, :terminate)
    end

    :ok
  end

  @impl Mcpixir.TaskManagers.Base
  def send_event(manager, event_type, data) do
    if manager.client_pid == nil do
      {:error, "WebSocket not connected"}
    else
      event = %{
        type: event_type,
        data: data,
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      WebSockex.send_frame(manager.client_pid, {:text, Jason.encode!(event)})
    end
  end

  # WebSockex callbacks

  @impl WebSockex
  def handle_connect(_conn, state) do
    {:ok, state}
  end

  @impl WebSockex
  def handle_frame({:text, _msg}, state) do
    # Ignore incoming messages for now
    {:ok, state}
  end

  @impl WebSockex
  def handle_disconnect(_conn, state) do
    # Try to reconnect
    {:reconnect, state}
  end
end
