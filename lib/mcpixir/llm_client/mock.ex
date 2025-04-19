defmodule Mcpixir.LLMClient.Mock do
  @moduledoc """
  Mock implementation of the LLM client.

  This module provides a mock implementation that can be used for testing
  or when no other LLM provider is available.
  """

  @behaviour Mcpixir.LLMClient.Base

  @impl true
  def run(_client, _messages) do
    {:ok,
     %{
       "role" => "assistant",
       "content" => "This is a placeholder LLM response from the mock provider."
     }}
  end
end
