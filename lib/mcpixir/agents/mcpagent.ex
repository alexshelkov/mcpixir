defmodule Mcpixir.Agents.MCPAgent do
  @moduledoc """
  Agent implementation that integrates LLMs with MCP tools.
  """

  @behaviour Mcpixir.Agents.Base

  # External reference to make module docs more complete
  @external_resource "README.md"

  alias Mcpixir.Agents.Prompts.SystemPromptBuilder
  alias Mcpixir.Client
  alias Mcpixir.LLMClient
  alias Mcpixir.Session

  @type t :: %__MODULE__{
          client: Mcpixir.Client.t(),
          llm_client: Mcpixir.LLMClient.t(),
          config: Mcpixir.Config.t(),
          sessions: [Mcpixir.Session.t()],
          tools: [Mcpixir.Tool.t()],
          messages: [Mcpixir.Message.t()],
          intermediate_steps: [Mcpixir.IntermediateStep.t()]
        }

  defstruct [
    :client,
    :llm_client,
    :config,
    sessions: [],
    tools: [],
    messages: [],
    intermediate_steps: []
  ]

  @doc """
  Creates a new MCP agent with the given configuration.
  """
  @impl Mcpixir.Agents.Base
  @spec new(map()) :: {:ok, t()}
  def new(config) do
    client = Client.new(config)

    agent = %__MODULE__{
      client: client,
      config: config
    }

    {:ok, agent}
  end

  @doc """
  Prepares the agent by initializing the LLM client and loading tools.
  """
  @impl Mcpixir.Agents.Base
  @spec prepare(t()) :: {:ok, t()} | {:error, String.t()}
  def prepare(agent) do
    with {:ok, llm_client} <- initialize_llm(agent.config),
         {:ok, tools} <- load_tools(agent) do
      updated_agent = %{agent | llm_client: llm_client, tools: tools}
      {:ok, updated_agent}
    else
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Runs a query using the agent.
  """
  @impl Mcpixir.Agents.Base
  @spec run(t(), String.t()) :: {:ok, String.t(), t()}
  def run(agent, query) do
    agent = add_message(agent, %{role: "user", content: query})

    system_prompt = SystemPromptBuilder.build(agent.tools)

    messages = [%{role: "system", content: system_prompt} | agent.messages]

    case LLMClient.run(agent.llm_client, messages) do
      {:ok, response} ->
        process_llm_response(agent, response)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Directly executes a tool using the agent.
  """
  @impl Mcpixir.Agents.Base
  @spec run_tool(t(), String.t(), map()) :: {:ok, any()} | {:error, any()}
  def run_tool(agent, tool_name, args) do
    case ensure_sessions_for_tool(agent, tool_name) do
      {:ok, sessions} ->
        execute_tool_in_sessions(sessions, tool_name, args)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp execute_tool_in_sessions(sessions, tool_name, args) do
    Enum.reduce_while(sessions, {:error, :tool_not_found}, fn session, acc ->
      case Session.execute_tool(session, tool_name, args) do
        {:ok, result} -> {:halt, {:ok, result}}
        _ -> {:cont, acc}
      end
    end)
  end

  defp initialize_llm(config) do
    llm_config = Map.get(config, :llm, %{})
    LLMClient.new(llm_config)
  end

  defp load_tools(agent) do
    tools_config = Map.get(agent.config, :tools, [])

    if Enum.empty?(tools_config) do
      tools = Client.get_tools(agent.client)
      {:ok, tools}
    else
      case Client.create_sessions_for_tools(agent.client, tools_config) do
        {:ok, updated_client, sessions} ->
          tools = Client.get_tools(updated_client)
          _updated_agent = %{agent | client: updated_client, sessions: sessions}
          {:ok, tools}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp add_message(agent, message) do
    %{agent | messages: agent.messages ++ [message]}
  end

  defp process_llm_response(agent, response) do
    updated_agent = add_message(agent, response)

    content = response["content"] || ""
    tool_calls = response["tool_calls"]

    if tool_calls && length(tool_calls) > 0 do
      process_tool_calls(updated_agent, tool_calls, content)
    else
      {:ok, content, updated_agent}
    end
  end

  defp process_tool_calls(agent, tool_calls, content) do
    {updated_agent, tool_results} =
      Enum.reduce(tool_calls, {agent, []}, fn tool_call, {current_agent, results} ->
        process_single_tool_call(current_agent, tool_call, results)
      end)

    handle_tool_results(updated_agent, tool_results, content)
  end

  defp process_single_tool_call(agent, tool_call, results) do
    tool_name = tool_call["name"] || tool_call["function"]["name"]
    arguments = tool_call["arguments"] || tool_call["function"]["arguments"]
    tool_call_id = tool_call["id"]
    args = parse_arguments(arguments)

    case run_tool(agent, tool_name, args) do
      {:ok, result} ->
        handle_successful_tool_call(agent, tool_call_id, tool_name, result, results)

      {:error, reason} ->
        handle_failed_tool_call(agent, tool_call_id, tool_name, reason, results)
    end
  end

  defp parse_arguments(arguments) do
    case arguments do
      args when is_binary(args) ->
        case Jason.decode(args) do
          {:ok, parsed} -> parsed
          _ -> %{}
        end

      args when is_map(args) ->
        args

      _ ->
        %{}
    end
  end

  defp handle_successful_tool_call(agent, tool_call_id, tool_name, result, results) do
    tool_result = %{
      "tool_call_id" => tool_call_id,
      "role" => "tool",
      "name" => tool_name,
      "content" => format_tool_result(result)
    }

    next_agent = add_message(agent, tool_result)
    {next_agent, [tool_result | results]}
  end

  defp handle_failed_tool_call(agent, tool_call_id, tool_name, reason, results) do
    error_result = %{
      "tool_call_id" => tool_call_id,
      "role" => "tool",
      "name" => tool_name,
      "content" => "Error: #{inspect(reason)}"
    }

    next_agent = add_message(agent, error_result)
    {next_agent, [error_result | results]}
  end

  defp handle_tool_results(agent, tool_results, content) do
    if length(tool_results) > 0 do
      process_tool_results_with_llm(agent, tool_results, content)
    else
      {:ok, content, agent}
    end
  end

  defp process_tool_results_with_llm(agent, _tool_results, content) do
    system_prompt = SystemPromptBuilder.build(agent.tools)
    messages = [%{role: "system", content: system_prompt} | agent.messages]

    case LLMClient.run(agent.llm_client, messages) do
      {:ok, response} ->
        process_llm_response(agent, response)

      {:error, reason} ->
        {:ok, "Error processing tool results: #{inspect(reason)}. Original response: #{content}",
         agent}
    end
  end

  defp format_tool_result(result) do
    case result do
      result when is_binary(result) ->
        result

      result when is_map(result) or is_list(result) ->
        case Jason.encode(result) do
          {:ok, json} -> json
          _ -> inspect(result)
        end

      nil ->
        "null"

      _ ->
        inspect(result)
    end
  end

  defp ensure_sessions_for_tool(agent, tool_name) do
    tool_sessions =
      Enum.filter(agent.sessions, fn session ->
        Enum.any?(Session.get_tools(session), fn tool ->
          tool["name"] == tool_name
        end)
      end)

    if Enum.empty?(tool_sessions) do
      create_new_sessions_for_tool(agent, tool_name)
    else
      {:ok, tool_sessions}
    end
  end

  defp create_new_sessions_for_tool(agent, tool_name) do
    case Client.create_sessions_for_tools(agent.client, [tool_name]) do
      {:ok, updated_client, new_sessions} ->
        _updated_agent = %{
          agent
          | client: updated_client,
            sessions: agent.sessions ++ new_sessions
        }

        {:ok, new_sessions}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
