defmodule Mcpixir.LLMClient.Base do
  @moduledoc """
  Base behaviour for LLM clients.
  
  This module defines the common behavior that all LLM client providers
  must implement. It allows for a consistent interface when working with
  different language models.
  """

  @doc """
  Run the LLM with the given messages and return a response.
  
  The messages should be a list of structured message maps containing at least:
  - role: The role of the message sender (system, user, assistant)
  - content: The content of the message
  
  Returns {:ok, response} where response is a map with at least:
  - role: always "assistant"
  - content: The generated response text
  - tool_calls: (optional) List of tool calls if the LLM wishes to use tools
  """
  @callback run(Mcpixir.LLMClient.t(), list()) :: {:ok, map()} | {:error, String.t()}
end