defmodule Mix.Tasks.Mcpixir.Browser do
  @moduledoc """
  Demonstrates using Mcpixir to control a web browser via Playwright MCP.

  This task allows controlling a web browser through natural language commands
  processed by an LLM.

  ## Usage

      mix mcpixir.browser

  ## Options

      --provider=PROVIDER   LLM provider (openai or anthropic, default: openai)
      --model=MODEL         Model to use (default: gpt-4o for OpenAI, claude-3-opus-20240229 for Anthropic)
      --query=QUERY         Query to send to the LLM (default is GitHub navigation)
      --config=PATH         Path to Browser MCP config file (optional)
      --url=URL             Initial URL to navigate to (default: https://github.com/mcp-use/mcp-use)

  ## Examples

      mix mcpixir.browser
      mix mcpixir.browser --provider=anthropic
      mix mcpixir.browser --url=https://elixir-lang.org --query="Summarize the Elixir homepage"

  """
  use Mix.Task

  alias Mcpixir

  @shortdoc "Runs a web browser automation example with an LLM"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          provider: :string,
          model: :string,
          query: :string,
          config: :string,
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
    url = Keyword.get(opts, :url, "https://github.com/mcp-use/mcp-use")

    query =
      Keyword.get(opts, :query, """
      Navigate to #{url}, and write a summary of what this website is about.
      """)

    config_path = Keyword.get(opts, :config)

    run_browser_example(provider, model, query, config_path)
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

  defp run_browser_example(provider, model, query, config_path) do
    # Explicitly ensure LangChain is started
    Application.ensure_all_started(:langchain)
    
    # Skip the LangChain check since we've made it a required dependency
    
    # Load required API keys
    load_api_keys()

    # Show banner
    IO.puts(IO.ANSI.bright() <> "MCP-Use Browser Example" <> IO.ANSI.reset())
    IO.puts("Provider: #{provider}, Model: #{model}\n")

    # Load or create Browser configuration
    config =
      if config_path do
        # Use provided config file
        {:ok, config_data} = File.read(config_path)
        {:ok, config} = Jason.decode(config_data)
        config
      else
        # Create default config
        %{
          "mcpServers" => %{
            "playwright" => %{
              "command" => "npx",
              "args" => ["@playwright/mcp@latest"],
              "env" => %{
                "DISPLAY" => ":1"
              }
            }
          }
        }
      end

    # Create LLM configuration
    llm_config = %{
      provider: String.to_atom(provider),
      model: model
    }

    IO.puts("Connecting to Playwright MCP server...")

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
