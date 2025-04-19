defmodule Mcpixir.IntermediateStep do
  @moduledoc """
  Represents an intermediate step in agent execution.
  """

  @type t :: %__MODULE__{
          tool: String.t(),
          args: map(),
          result: any()
        }

  defstruct [
    :tool,
    :args,
    :result
  ]
end
