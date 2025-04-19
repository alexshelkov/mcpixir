#!/usr/bin/env elixir
# Basic usage example for mcp_use.
#
# This example demonstrates how to use the mcp_use library with MCPClient
# to connect any LLM to MCP tools through a unified interface.
#
# Special thanks to https://github.com/microsoft/playwright-mcp for the server.

# Make sure to run this from the project root:
# $ elixir examples/browser_use.exs

defmodule BrowserExample do
  def run do
    IO.puts("Running Browser MCP Example")

    # Load Browser configuration
    config_path = Path.join(__DIR__, "browser_mcp.json")
    {:ok, config_data} = File.read(config_path)
    {:ok, config} = Jason.decode(config_data)

    # Extract the command and args for the Browser server
    browser_config = get_in(config, ["mcpServers", "playwright"])
    command = "#{browser_config["command"]} #{Enum.join(browser_config["args"], " ")}"
    server_url = "stdio:#{command}"

    IO.puts("Connecting to Playwright MCP server...")

    # Create the MCP client
    client =
      Mcpixir.new_client(%{
        servers: [server_url]
      })

    # Configure LLM (in a real implementation)
    llm_config = %{
      provider: :openai,
      model: "gpt-4o"
    }

    # Create agent
    IO.puts("Creating MCP agent...")

    # In a real implementation, this would be:
    # {:ok, agent} = Mcpixir.new_agent(%{
    #   llm: llm_config,
    #   client: client
    # })
    #
    # For now, we'll simulate the agent

    # Simulate running a query
    query = """
    Navigate to https://github.com/mcp-use/mcp-use, give a star to the project and write
    a summary of the project.
    """

    IO.puts("\nQuerying: #{query}")

    # Simulate the agent's steps
    IO.puts("\nExecuting steps:")
    IO.puts("1. Opening new browser instance...")
    IO.puts("2. Navigating to https://github.com/mcp-use/mcp-use...")
    IO.puts("3. Waiting for page to load...")
    IO.puts("4. Clicking the 'Star' button...")
    IO.puts("5. Reading repository information...")

    # Simulate the result
    result = """
    I've navigated to the MCP-Use GitHub repository and starred the project. Here's a summary:

    MCP-Use is an open-source Python library designed to connect language learning models (LLMs) to MCP (Machine Control Protocol) servers. It creates a unified interface that allows AI agents to access external tools like web browsers, file systems, and applications through the MCP protocol.

    Key features:
    - Supports various LLMs (OpenAI, Anthropic, etc.)
    - Compatible with multiple MCP servers (browser, Airbnb, Blender)
    - Provides both synchronous and asynchronous APIs
    - Includes tools for debugging and logging
    - Easy integration with existing LangChain workflows

    The repository contains examples showing how to use MCP-Use with different tools and scenarios, like browsing the web, searching for Airbnb accommodations, and controlling Blender 3D software.
    """

    IO.puts("\nResult: #{result}")

    IO.puts(
      "\nExample completed! In a real implementation, this would control a browser via the MCP server."
    )
  end
end

# Create the browser_mcp.json file if it doesn't exist
config_path = Path.join(__DIR__, "browser_mcp.json")
browser_config = ~s({
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"],
      "env": {
        "DISPLAY": ":1"
      }
    }
  }
})

File.write(config_path, browser_config)

# Run the example
BrowserExample.run()
