defmodule Mcpixir.Message do
  @moduledoc """
  Represents a message in a conversation.
  """

  @type t :: %__MODULE__{
          role: String.t(),
          content: String.t()
        }

  defstruct [
    :role,
    :content
  ]
end
