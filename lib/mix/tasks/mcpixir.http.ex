defmodule Mix.Tasks.Mcpixir.Http do
  @moduledoc """
  Demonstrates using Mcpixir to connect to an MCP server via HTTP.

  This task connects to an MCP server running on a specific HTTP port
  and sends queries via an LLM.

  ## Prerequisites

  Before running this task, you need to start the Playwright MCP server
  in another terminal with:

      npx @playwright/mcp@latest --port 8931

  ## Usage

      mix mcpixir.http

  ## Options

      --provider=PROVIDER   LLM provider (openai or anthropic, default: openai)
      --model=MODEL         Model to use (default: gpt-4o for OpenAI, claude-3-sonnet-20240229 for Anthropic)
      --query=QUERY         Query to send to the LLM (default is restaurant search)
      --url=URL             MCP server URL (default: http://localhost:8931/sse)

  ## Examples

      mix mcpixir.http
      mix mcpixir.http --provider=anthropic
      mix mcpixir.http --query="Find hotels in New York with rooftop bars"

  """
  use Mix.Task

  alias Mcpixir

  @shortdoc "Runs an HTTP MCP server example with an LLM"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          provider: :string,
          model: :string,
          query: :string,
          url: :string
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

    query =
      Keyword.get(opts, :query, "Find the best restaurant in San Francisco USING GOOGLE SEARCH")

    url = Keyword.get(opts, :url, "http://localhost:8931/sse")

    run_http_example(provider, model, query, url)
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

  defp run_http_example(provider, model, query, url) do
    # Explicitly ensure LangChain is started
    Application.ensure_all_started(:langchain)
    
    # Skip the LangChain check since we've made it a required dependency
    
    # Load required API keys
    load_api_keys()

    # Show banner
    IO.puts(IO.ANSI.bright() <> "MCP-Use HTTP Example" <> IO.ANSI.reset())
    IO.puts("Provider: #{provider}, Model: #{model}")
    IO.puts("Server URL: #{url}\n")

    # Remind user to start the server
    IO.puts(
      IO.ANSI.yellow() <>
        "Make sure you've started the Playwright MCP server with:" <>
        IO.ANSI.reset()
    )

    IO.puts("  npx @playwright/mcp@latest --port 8931\n")

    # Create HTTP configuration
    config = %{
      "mcpServers" => %{
        "http" => %{
          "url" => url
        }
      }
    }

    # Create LLM configuration
    llm_config = %{
      provider: String.to_atom(provider),
      model: model
    }

    IO.puts("Connecting to MCP server...")

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
