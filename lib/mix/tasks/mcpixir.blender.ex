defmodule Mix.Tasks.Mcpixir.Blender do
  @moduledoc """
  Demonstrates using Mcpixir to control Blender 3D via MCP.

  This task allows controlling Blender through natural language commands
  processed by an LLM.

  ## Prerequisites

  You need to have the Blender MCP addon installed from:
  https://github.com/ahujasid/blender-mcp

  Make sure the addon is enabled in Blender preferences and the
  WebSocket server is running before executing this task.

  ## Usage

      mix mcpixir.blender

  ## Options

      --provider=PROVIDER   LLM provider (openai or anthropic, default: anthropic)
      --model=MODEL         Model to use (default: claude-3-sonnet-20240229 for Anthropic, gpt-4o for OpenAI)
      --query=QUERY         Query to send to the LLM (default is a cube creation)
      --command=COMMAND     Command to launch Blender MCP server (default: "uvx blender-mcp")

  ## Examples

      mix mcpixir.blender
      mix mcpixir.blender --provider=openai
      mix mcpixir.blender --query="Create a red torus floating above a blue plane"

  """
  use Mix.Task

  alias Mcpixir

  @shortdoc "Runs a Blender 3D modeling example with an LLM"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          provider: :string,
          model: :string,
          query: :string,
          command: :string
        ]
      )

    # Load applications
    Application.ensure_all_started(:mcpixir)
    Application.ensure_all_started(:httpoison)
    Application.ensure_all_started(:jason)
    Application.ensure_all_started(:langchain)
    
    # Force load LangChain core modules
    Code.ensure_loaded?(LangChain) 
    Code.ensure_loaded?(LangChain.Message)
    Code.ensure_loaded?(LangChain.ChatModels)

    # Get LLM provider and model
    provider = Keyword.get(opts, :provider, "anthropic")
    model = get_default_model(provider, Keyword.get(opts, :model))

    query =
      Keyword.get(
        opts,
        :query,
        "Create an inflatable cube with soft material and a plane as ground."
      )

    command = Keyword.get(opts, :command, "uvx blender-mcp")

    run_blender_example(provider, model, query, command)
  end

  defp get_default_model(provider, model) do
    if model do
      model
    else
      case provider do
        "anthropic" -> "claude-3-sonnet-20240229"
        _ -> "gpt-4o"
      end
    end
  end

  defp run_blender_example(provider, model, query, command) do
    # Explicitly ensure LangChain is started
    Application.ensure_all_started(:langchain)
    
    # Skip the LangChain check since we've made it a required dependency
    
    # Load required API keys
    load_api_keys()

    # Show banner
    IO.puts(IO.ANSI.bright() <> "Mcpixir Blender Example" <> IO.ANSI.reset())
    IO.puts("Provider: #{provider}, Model: #{model}\n")

    # Create Blender configuration
    config = %{
      "mcpServers" => %{
        "blender" => %{
          "command" => "stdio:#{command}"
        }
      }
    }

    # Create LLM configuration
    llm_config = %{
      provider: String.to_atom(provider),
      model: model
    }

    IO.puts("Connecting to Blender MCP server...")

    # Create the MCP client
    client = Mcpixir.new_client(config)

    IO.puts("Creating MCP agent...")

    # Create a real agent connected to the LLM
    {:ok, agent} =
      Mcpixir.new_agent(%{
        llm: llm_config,
        client: client
      })

    # Run the chat
    IO.puts("\nUser query: #{query}")

    start_time = :os.system_time(:millisecond)

    {:ok, result, _updated_agent} = Mcpixir.run(agent, query)

    end_time = :os.system_time(:millisecond)
    duration = (end_time - start_time) / 1000

    IO.puts("\nResult (completed in #{duration}s):")
    IO.puts("------------------------------")
    IO.puts(result)
    IO.puts("------------------------------")

    # Clean up
    Mcpixir.Client.stop_all_sessions(client)
  end

  defp load_api_keys do
    # Check for API keys in environment variables
    openai_key = System.get_env("OPENAI_API_KEY")
    anthropic_key = System.get_env("ANTHROPIC_API_KEY")

    if is_nil(openai_key) do
      IO.puts(
        IO.ANSI.yellow() <>
          "Warning: OPENAI_API_KEY environment variable not set. " <>
          "OpenAI models won't work without it." <>
          IO.ANSI.reset()
      )
    end

    if is_nil(anthropic_key) do
      IO.puts(
        IO.ANSI.yellow() <>
          "Warning: ANTHROPIC_API_KEY environment variable not set. " <>
          "Anthropic models won't work without it." <>
          IO.ANSI.reset()
      )
    end
  end
end
