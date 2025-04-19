defmodule Mix.Tasks.Mcpixir.Airbnb do
  @moduledoc """
  Demonstrates using Mcpixir to connect an LLM to Airbnb through MCP tools.

  This task allows searching for accommodations on Airbnb using
  natural language queries processed by an LLM.

  ## Usage

      mix mcpixir.airbnb

  ## Options

      --provider=PROVIDER   LLM provider (openai or anthropic, default: anthropic)
      --model=MODEL         Model to use (default: claude-3-sonnet-20240229 for Anthropic, gpt-4o for OpenAI)
      --query=QUERY         Query to send to the LLM (default is Barcelona search)
      --config=PATH         Path to Airbnb MCP config file (optional)

  ## Examples

      mix mcpixir.airbnb
      mix mcpixir.airbnb --provider=openai
      mix mcpixir.airbnb --query="Find me a beachfront place in Miami for 4 people in December"

  """
  use Mix.Task

  alias Mcpixir

  @shortdoc "Runs an Airbnb search example with an LLM"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          provider: :string,
          model: :string,
          query: :string,
          config: :string
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
      Keyword.get(opts, :query, """
      Find me a nice place to stay in Barcelona for 2 adults
      for a week in August. I prefer places with a pool and
      good reviews. Show me the top 3 options.
      """)

    config_path = Keyword.get(opts, :config)

    run_airbnb_example(provider, model, query, config_path)
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

  defp run_airbnb_example(provider, model, query, config_path) do
    # Start the application to ensure all dependencies are loaded
    Application.ensure_all_started(:mcpixir)

    # Explicitly ensure LangChain is started
    Application.ensure_all_started(:langchain)

    # Skip the LangChain check since we've made it a required dependency
    # Load required API keys
    load_api_keys()

    # Show banner
    IO.puts(IO.ANSI.bright() <> "Mcpixir Airbnb Example" <> IO.ANSI.reset())
    IO.puts("Provider: #{provider}, Model: #{model}\n")

    # Load or create Airbnb configuration
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
            "airbnb" => %{
              "command" => "npx",
              "args" => ["-y", "@openbnb/mcp-server-airbnb", "--ignore-robots-txt"]
            }
          }
        }
      end

    # Create LLM configuration
    llm_config = %{
      provider: String.to_atom(provider),
      model: model
    }

    IO.puts("Connecting to Airbnb MCP server...")

    # Create the MCP client
    {:ok, client} = Mcpixir.new_client(config)

    # Register the server and initialize connection
    Mcpixir.ServerManager.register_server("airbnb", config["mcpServers"]["airbnb"])

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
