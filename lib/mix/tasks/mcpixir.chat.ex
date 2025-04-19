defmodule Mix.Tasks.Mcpixir.Chat do
  @moduledoc """
  Demonstrates a basic chat interaction with an LLM using Mcpixir.

  This task connects to an LLM (OpenAI or Anthropic) and allows
  for a simple chat interaction using weather tools.

  ## Usage

      mix mcpixir.chat

  ## Options

      --provider=PROVIDER   LLM provider (openai or anthropic, default: openai)
      --model=MODEL         Model to use (default: gpt-4o for OpenAI, claude-3-opus-20240229 for Anthropic)
      --query=QUERY         Query to send to the LLM (default: "What's the weather like in San Francisco?")

  ## Examples

      mix mcpixir.chat
      mix mcpixir.chat --provider=anthropic
      mix mcpixir.chat --model=gpt-4o --query="What's the weather like in London?"

  """
  use Mix.Task

  alias Mcpixir

  @shortdoc "Runs a chat example with an LLM"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          provider: :string,
          model: :string,
          query: :string
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
    provider = Keyword.get(opts, :provider, "openai")
    model = get_default_model(provider, Keyword.get(opts, :model))
    query = Keyword.get(opts, :query, "What's the weather like in San Francisco?")

    run_chat_example(provider, model, query)
  end

  defp get_default_model(provider, model) do
    if model do
      model
    else
      case provider do
        "anthropic" -> "claude-3-opus-20240229"
        _ -> "gpt-4o"
      end
    end
  end

  defp run_chat_example(provider, model, query) do
    # Explicitly ensure LangChain is started
    Application.ensure_all_started(:langchain)

    # Skip the LangChain check since we've made it a required dependency
    # Load required API keys
    load_api_keys()

    # Show banner
    IO.puts(IO.ANSI.bright() <> "MCP-Use Chat Example" <> IO.ANSI.reset())
    IO.puts("Provider: #{provider}, Model: #{model}\n")

    # Create configuration with real LLM settings
    llm_config = %{
      provider: String.to_atom(provider),
      model: model
    }

    # Create configuration for MCP server
    config = %{
      mcpServers: %{
        weather: %{
          command: "npx",
          args: ["-y", "@mcp/server-weather"]
        }
      }
    }

    IO.puts("Creating MCP client...")
    client = Mcpixir.new_client(config)

    IO.puts("Creating MCP agent...")

    # Create a real agent connected to the LLM
    {:ok, agent} =
      Mcpixir.new_agent(%{
        llm: llm_config,
        client: client
      })

    # Run the chat
    IO.puts("\nUser: #{query}")

    {:ok, result, _updated_agent} = Mcpixir.run(agent, query)

    IO.puts("\nAssistant: #{result}")

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
