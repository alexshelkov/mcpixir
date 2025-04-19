defmodule Mcpixir.Agents.Prompts.SystemPromptBuilder do
  @moduledoc """
  Builds system prompts for MCP agents.
  """

  alias Mcpixir.Agents.Prompts.Templates

  @doc """
  Builds a system prompt with the given tools.
  """
  def build(tools) do
    base_prompt = Templates.base_system_prompt()
    tools_description = build_tools_description(tools)

    base_prompt <> "\n\n" <> tools_description
  end

  @doc """
  Builds a description of available tools for the prompt.
  """
  def build_tools_description(tools) do
    tools_json = Jason.encode!(tools, pretty: true)

    """
    # Available Tools

    You have access to the following tools:

    ```json
    #{tools_json}
    ```

    To use a tool, respond with:
    <tool_calls>
    <tool name="TOOL_NAME" input={TOOL_INPUT_JSON} />
    </tool_calls>

    Where TOOL_NAME is the name of the tool to use, and TOOL_INPUT_JSON is a JSON object
    with the input parameters for the tool.
    """
  end
end
