defmodule Mcpixir.TaskManagers.StdioManager do
  @moduledoc """
  Task manager that outputs events to stdio.
  """

  @behaviour Mcpixir.TaskManagers.Base

  defstruct [
    :config
  ]

  @impl Mcpixir.TaskManagers.Base
  def new(config) do
    {:ok, %__MODULE__{config: config}}
  end

  @impl Mcpixir.TaskManagers.Base
  def start(manager) do
    # Nothing to start for stdio
    {:ok, manager}
  end

  @impl Mcpixir.TaskManagers.Base
  def stop(_manager) do
    # Nothing to stop for stdio
    :ok
  end

  @impl Mcpixir.TaskManagers.Base
  def send_event(_manager, event_type, data) do
    event = %{
      type: event_type,
      data: data,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    IO.puts(Jason.encode!(event))
    :ok
  end
end
