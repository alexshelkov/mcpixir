defmodule Mcpixir.Agents.Prompts.Templates do
  @moduledoc """
  Templates for MCP agent prompts.
  """

  @doc """
  Base system prompt template for MCP agents.
  """
  def base_system_prompt do
    """
    You are a helpful AI assistant with access to external tools.

    When interacting with tools:
    1. Use tools when necessary to complete tasks
    2. Wait for tool execution results before continuing
    3. Use results from tool calls to inform your responses
    4. Do not make up or hallucinate tool results

    Follow these guidelines:
    - Be concise, clear, and helpful
    - Be honest when you don't know something or need more information
    - If a task requires multiple steps, break it down clearly
    - When handling code, provide explanations unless told otherwise
    """
  end

  @doc """
  Template for task-specific prompts.
  """
  def task_specific_prompt(task) do
    """
    # Task

    #{task}

    Complete this task step by step, using available tools when necessary.
    """
  end
end
