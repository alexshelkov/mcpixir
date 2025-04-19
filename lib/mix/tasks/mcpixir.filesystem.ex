defmodule Mix.Tasks.Mcpixir.Filesystem do
  @moduledoc """
  Demonstrates using Mcpixir to interact with the filesystem via MCP.

  This task allows querying and manipulating the filesystem using
  natural language commands processed by an LLM.

  ## Usage

      mix mcpixir.filesystem

  ## Options

      --provider=PROVIDER   LLM provider (openai or anthropic, default: openai)
      --model=MODEL         Model to use (default: gpt-4o for OpenAI, claude-3-sonnet-20240229 for Anthropic)
      --query=QUERY         Query to send to the LLM (default lists files in current dir)
      --path=PATH           Directory path to use for filesystem operations (default: current directory)

  ## Examples

      mix mcp.filesystem
      mix mcp.filesystem --provider=anthropic
      mix mcp.filesystem --path=/tmp --query="Create a text file named test.txt with hello world in it"

  """
  use Mix.Task

  alias Mcpixir

  @shortdoc "Runs a filesystem interaction example with an LLM"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          provider: :string,
          model: :string,
          query: :string,
          path: :string
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
      Keyword.get(
        opts,
        :query,
        "Can you give me a list of files and directories in the current directory, organized by type?"
      )

    path = Keyword.get(opts, :path, File.cwd!())

    run_filesystem_example(provider, model, query, path)
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

  defp run_filesystem_example(provider, model, query, path) do
    # Explicitly ensure LangChain is started
    Application.ensure_all_started(:langchain)

    # Skip the LangChain check since we've made it a required dependency
    # Load required API keys
    load_api_keys()

    # Show banner
    IO.puts(IO.ANSI.bright() <> "MCP-Use Filesystem Example" <> IO.ANSI.reset())
    IO.puts("Provider: #{provider}, Model: #{model}")
    IO.puts("Path: #{path}\n")

    # Create filesystem configuration
    config = %{
      "mcpServers" => %{
        "filesystem" => %{
          "command" => "npx",
          "args" => [
            "-y",
            "@modelcontextprotocol/server-filesystem",
            # Use the provided path
            path
          ]
        }
      }
    }

    # Create LLM configuration
    llm_config = %{
      provider: String.to_atom(provider),
      model: model
    }

    IO.puts("Connecting to Filesystem MCP server...")

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
