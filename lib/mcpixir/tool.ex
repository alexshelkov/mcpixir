defmodule Mcpixir.Tool do
  @moduledoc """
  Represents a tool that can be executed by MCP.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          parameters: map()
        }

  defstruct [
    :name,
    :description,
    :parameters
  ]
end
