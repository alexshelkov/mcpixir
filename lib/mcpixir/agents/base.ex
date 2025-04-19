defmodule Mcpixir.Agents.Base do
  @moduledoc """
  Base behaviour for MCP agents.
  """

  @callback new(map()) :: {:ok, map()}
  @callback prepare(map()) :: {:ok, map()} | {:error, any()}
  @callback run(map(), String.t()) :: {:ok, String.t(), map()}
  @callback run_tool(map(), String.t(), map()) :: {:ok, any()} | {:error, any()}
end
