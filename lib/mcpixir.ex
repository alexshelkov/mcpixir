defmodule Mcpixir do
  @moduledoc """
  Mcpixir is a library for connecting LLMs (Language Learning Models) to MCP (Machine Control Protocol) servers.

  This library enables AI agents to access external tools like web browsing, file operations,
  and specific applications through a unified interface. It's designed to connect any LLM
  to various tools through MCP servers.

  ## Main Features

  * **LLM Integration**: Connect any LLM with tool-calling capabilities (OpenAI, Anthropic, etc.)
  * **Multiple Connection Types**: Support for HTTP, WebSocket, and stdio connections
  * **Server Management**: Use multiple MCP servers simultaneously, with dynamic server selection
  * **Comprehensive Tool Access**: Interact with web browsers, file systems, and specialized applications
  * **Easy Configuration**: Simple configuration options via code or JSON files

  ## Getting Started

  Create a client and agent:

  ```elixir
  # Create a client with a configuration
  client = Mcpixir.new_client(%{
    mcpServers: %{
      browser: %{
        command: "npx",
        args: ["@playwright/mcp@latest"]
      }
    }
  })

  # Create an agent with an LLM
  {:ok, agent} = Mcpixir.new_agent(%{
    llm: %{
      provider: :openai,
      model: "gpt-4o"
    },
    client: client
  })

  # Run a query
  {:ok, result, updated_agent} = Mcpixir.run(agent, "Search for Elixir libraries on GitHub")
  ```

  ## Examples

  The library includes several Mix tasks for demonstrating various use cases:

  ```bash
  # Run the browser example
  mix mcp.browser

  # Run the Airbnb search example with Anthropic
  mix mcp.airbnb --provider=anthropic
  ```

  See the README for more detailed examples and the full API reference.
  """

  alias Mcpixir.Agents.MCPAgent
  alias Mcpixir.Client
  alias Mcpixir.Config

  @doc """
  Creates a new MCP client with the given configuration.
  """
  @spec new_client(map()) :: {:ok, Client.t()} | {:error, any()}
  def new_client(config \\ %{}) do
    {:ok, Client.new(config)}
  end

  @doc """
  Creates a new MCP agent with the given configuration.
  """
  @spec new_agent(map()) :: {:ok, Mcpixir.Agents.MCPAgent.t()} | {:error, String.t()}
  def new_agent(config \\ %{}) do
    config = struct(Config, config)

    case MCPAgent.new(config) do
      {:ok, agent} ->
        case MCPAgent.prepare(agent) do
          {:ok, prepared_agent} -> {:ok, prepared_agent}
          {:error, _} -> {:error, "Failed to prepare agent"}
        end

      _ ->
        {:error, "Failed to create agent"}
    end
  end

  @doc """
  Runs a query using an MCP agent.
  """
  @spec run(Mcpixir.Agents.MCPAgent.t(), String.t()) ::
          {:ok, String.t(), Mcpixir.Agents.MCPAgent.t()}
  def run(agent, query) do
    MCPAgent.run(agent, query)
  end

  @doc """
  Executes a specific tool using an MCP agent.
  """
  @spec run_tool(Mcpixir.Agents.MCPAgent.t(), String.t(), map()) :: {:ok, any()} | {:error, any()}
  def run_tool(agent, tool_name, args) do
    MCPAgent.run_tool(agent, tool_name, args)
  end

  @doc """
  Sets the log level for the MCP library.
  """
  @spec set_log_level(atom()) :: :ok
  def set_log_level(level) do
    Mcpixir.Logging.set_level(level)
  end

  @doc """
  Returns the version of the MCP library.
  """
  @spec version() :: String.t()
  def version do
    Application.spec(:mcpixir, :vsn)
  end
end
