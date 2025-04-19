defmodule Mix.Tasks.Mcpixir.Multi do
  @moduledoc """
  Demonstrates using Mcpixir with multiple MCP servers at once.

  This task shows how to:
  1. Configure multiple MCP servers
  2. Create and manage sessions for each server
  3. Use tools from different servers in a single agent

  ## Usage

      mix mcpixir.multi

  ## Options

      --provider=PROVIDER   LLM provider (openai or anthropic, default: anthropic)
      --model=MODEL         Model to use (default: claude-3-sonnet-20240229 for Anthropic, gpt-4o for OpenAI)
      --query=QUERY         Query to send to the LLM (default is Barcelona travel query)
      --servers=SERVERS     Comma-separated list of servers to use (default: "airbnb,playwright,filesystem")

  ## Examples

      mix mcpixir.multi
      mix mcpixir.multi --provider=openai
      mix mcpixir.multi --servers=airbnb,playwright

  """
  use Mix.Task

  alias Mcpixir

  @shortdoc "Runs a multi-server example with an LLM"

  @impl Mix.Task
  @spec run([String.t()]) :: :ok
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          provider: :string,
          model: :string,
          query: :string,
          servers: :string
        ]
      )

    # Load applications
    Application.ensure_all_started(:mcpixir)
    Application.ensure_all_started(:httpoison)
    Application.ensure_all_started(:jason)

    # Get LLM provider and model
    provider = Keyword.get(opts, :provider, "anthropic")
    model = get_default_model(provider, Keyword.get(opts, :model))

    query =
      Keyword.get(opts, :query, """
      Search for a nice place to stay in Barcelona on Airbnb,
      then use Google to find nearby restaurants and attractions.
      Write the result in the current directory in restaurant.txt
      """)

    # Parse servers list
    servers_str = Keyword.get(opts, :servers, "airbnb,playwright,filesystem")
    servers = String.split(servers_str, ",", trim: true)

    run_multi_server_example(provider, model, query, servers)
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

  @spec run_multi_server_example(String.t(), String.t(), String.t(), [String.t()]) :: :ok
  defp run_multi_server_example(provider, model, query, servers) do
    # Load required API keys
    load_api_keys()

    # Show banner
    IO.puts(IO.ANSI.bright() <> "MCP-Use Multi-Server Example" <> IO.ANSI.reset())
    IO.puts("Provider: #{provider}, Model: #{model}")
    IO.puts("Servers: #{Enum.join(servers, ", ")}\n")

    # Create configuration with selected servers
    config = %{
      "mcpServers" => create_servers_config(servers)
    }

    # Create LLM configuration
    llm_config = %{
      provider: String.to_atom(provider),
      model: model
    }

    IO.puts("Connecting to multiple MCP servers...")

    # Create the MCP client
    client = Mcpixir.new_client(config)

    IO.puts("Creating MCP agent with access to all servers...")

    # Create a real agent connected to the LLM with server manager enabled
    {:ok, agent} =
      Mcpixir.new_agent(%{
        llm: llm_config,
        client: client,
        # Enable dynamic server selection
        use_server_manager: true
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

  defp create_servers_config(servers) do
    base_configs = %{
      "airbnb" => %{
        "command" => "npx",
        "args" => ["-y", "@openbnb/mcp-server-airbnb", "--ignore-robots-txt"]
      },
      "playwright" => %{
        "command" => "npx",
        "args" => ["@playwright/mcp@latest"],
        "env" => %{
          "DISPLAY" => ":1"
        }
      },
      "filesystem" => %{
        "command" => "npx",
        "args" => [
          "-y",
          "@modelcontextprotocol/server-filesystem",
          # Use current directory
          "."
        ]
      }
    }

    # Filter for only the requested servers
    servers
    |> Enum.reduce(%{}, fn server, acc ->
      if Map.has_key?(base_configs, server) do
        Map.put(acc, server, Map.get(base_configs, server))
      else
        IO.puts(
          IO.ANSI.yellow() <>
            "Warning: Unknown server type '#{server}'. Ignoring." <>
            IO.ANSI.reset()
        )

        acc
      end
    end)
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
