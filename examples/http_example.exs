#!/usr/bin/env elixir
# HTTP Example for mcp_use.
#
# This example demonstrates how to use the mcp_use library with MCPClient
# to connect to an MCP server running on a specific HTTP port.
#
# Before running this example, you need to start the Playwright MCP server
# in another terminal with:
#
#     npx @playwright/mcp@latest --port 8931
#
# This will start the server on port 8931. Resulting in the config you find below.
# Of course you can run this with any server you want at any URL.
#
# Special thanks to https://github.com/microsoft/playwright-mcp for the server.

# Make sure to run this from the project root:
# $ elixir examples/http_example.exs

defmodule HttpExample do
  def run do
    IO.puts("Running HTTP MCP Example")

    # Create HTTP configuration
    config = %{
      mcpServers: %{
        http: %{
          url: "http://localhost:8931/sse"
        }
      }
    }

    # Extract the server URL
    server_url = config.mcpServers.http.url

    IO.puts("Connecting to MCP server at: #{server_url}")
    IO.puts("Make sure you've started the server with:")
    IO.puts("  npx @playwright/mcp@latest --port 8931")

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
    IO.puts("\nCreating MCP agent...")

    # In a real implementation, this would be:
    # {:ok, agent} = Mcpixir.new_agent(%{
    #   llm: llm_config,
    #   client: client
    # })
    #
    # For now, we'll simulate the agent

    # Simulate running a query
    query = "Find the best restaurant in San Francisco USING GOOGLE SEARCH"

    IO.puts("\nQuerying: #{query}")

    # Simulate the agent's steps
    IO.puts("\nExecuting steps:")
    IO.puts("1. Opening new browser instance...")
    IO.puts("2. Navigating to https://www.google.com...")
    IO.puts("3. Searching for 'best restaurant in San Francisco'...")
    IO.puts("4. Reading search results...")
    IO.puts("5. Visiting restaurant review sites...")
    IO.puts("6. Analyzing top-rated restaurants...")

    # Simulate the result
    result = """
    Based on my search, here are some of the best restaurants in San Francisco according to recent reviews and ratings:

    1. Lazy Bear - A two Michelin-starred restaurant offering an innovative American tasting menu with communal dining. Known for their creative presentations and seasonal ingredients.

    2. Benu - A three Michelin-starred restaurant by Chef Corey Lee serving Asian-influenced contemporary cuisine with a focus on innovative techniques and presentations.

    3. Acquerello - A Michelin-starred Italian fine dining establishment known for elegant atmosphere and sophisticated Italian cuisine with California influences.

    4. Quince - A three Michelin-starred restaurant offering refined contemporary Californian cuisine with Italian influences in an elegant setting.

    5. State Bird Provisions - Known for their creative dim sum-style service of contemporary American small plates. Has received a Michelin star and is popular for its unique dining concept.

    These restaurants consistently appear at the top of various "best of San Francisco" lists and have excellent ratings across multiple review platforms. Reservations are generally required well in advance, especially for Lazy Bear, Benu, and Quince.
    """

    IO.puts("\nResult: #{result}")

    IO.puts(
      "\nExample completed! In a real implementation, this would use a browser via the MCP server over HTTP."
    )
  end
end

# Run the example
HttpExample.run()
