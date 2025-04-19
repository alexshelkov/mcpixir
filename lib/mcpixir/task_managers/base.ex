defmodule Mcpixir.TaskManagers.Base do
  @moduledoc """
  Base behaviour for task managers.
  """

  @type manager() :: map()

  @callback new(map()) :: {:ok, manager()} | {:error, any()}
  @callback start(manager()) :: {:ok, manager()} | {:error, any()}
  @callback stop(manager()) :: :ok | {:error, any()}
  @callback send_event(manager(), String.t(), any()) :: :ok | {:error, any()}
end
