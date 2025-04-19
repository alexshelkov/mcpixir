#!/usr/bin/env elixir
# Example demonstrating how to use MCPClient with multiple servers.
#
# This example shows how to:
# 1. Configure multiple MCP servers
# 2. Create and manage sessions for each server
# 3. Use tools from different servers in a single agent

# Make sure to run this from the project root:
# $ elixir examples/multi_server_example.exs

# When running with `mix run`, all dependencies and modules are properly loaded.
# See README.md for instructions on how to run examples.

defmodule MultiServerExample do
  def run do
    IO.puts("Running Multi-Server MCP Example")

    # Create a configuration with multiple servers
    config = %{
      mcpServers: %{
        airbnb: %{
          command: "npx",
          args: ["-y", "@openbnb/mcp-server-airbnb", "--ignore-robots-txt"]
        },
        playwright: %{
          command: "npx",
          args: ["@playwright/mcp@latest"],
          env: %{DISPLAY: ":1"}
        },
        filesystem: %{
          command: "npx",
          args: [
            "-y",
            "@modelcontextprotocol/server-filesystem",
            # Use current directory
            "."
          ]
        }
      }
    }

    # Extract the commands and create server URLs
    airbnb_command =
      "#{config.mcpServers.airbnb.command} #{Enum.join(config.mcpServers.airbnb.args, " ")}"

    playwright_command =
      "#{config.mcpServers.playwright.command} #{Enum.join(config.mcpServers.playwright.args, " ")}"

    filesystem_command =
      "#{config.mcpServers.filesystem.command} #{Enum.join(config.mcpServers.filesystem.args, " ")}"

    server_urls = [
      "stdio:#{airbnb_command}",
      "stdio:#{playwright_command}",
      "stdio:#{filesystem_command}"
    ]

    IO.puts("Connecting to multiple MCP servers:")
    IO.puts("- Airbnb MCP server")
    IO.puts("- Playwright MCP server")
    IO.puts("- Filesystem MCP server")

    # Create the MCP client with multiple servers
    client =
      Mcpixir.new_client(%{
        servers: server_urls
      })

    # Configure LLM (in a real implementation)
    llm_config = %{
      provider: :anthropic,
      model: "claude-3-5-sonnet"
    }

    # Create agent
    IO.puts("\nCreating MCP agent with access to all servers...")

    # In a real implementation, this would be:
    # {:ok, agent} = Mcpixir.new_agent(%{
    #   llm: llm_config,
    #   client: client
    # })
    #
    # For now, we'll simulate the agent

    # Simulate running a query
    query = """
    Search for a nice place to stay in Barcelona on Airbnb,
    then use Google to find nearby restaurants and attractions.
    Write the result in the current directory in restaurant.txt
    """

    IO.puts("\nQuerying: #{query}")

    # Simulate the agent's steps
    IO.puts("\nExecuting steps across multiple servers:")
    IO.puts("1. Connecting to Airbnb MCP server...")
    IO.puts("2. Searching for accommodations in Barcelona...")
    IO.puts("3. Finding highly-rated place with good location...")
    IO.puts("4. Connecting to Playwright MCP server...")
    IO.puts("5. Opening Google and searching for restaurants near the selected accommodation...")
    IO.puts("6. Gathering information about top restaurants and attractions...")
    IO.puts("7. Connecting to Filesystem MCP server...")
    IO.puts("8. Writing results to restaurant.txt...")

    # Simulate the result
    result = """
    I've completed the task using multiple tools:

    1. Using Airbnb tools, I found a beautiful apartment in Barcelona's Gothic Quarter with a 4.9-star rating. It's centrally located and costs €175 per night.

    2. Using the browser tools, I searched for nearby restaurants and attractions and found:
       - Top Restaurants: El Xampanyet (traditional tapas), Bodega Biarritz (modern tapas), and Can Culleretes (oldest restaurant in Barcelona)
       - Top Attractions: Barcelona Cathedral (5-minute walk), Picasso Museum (8-minute walk), and La Rambla (10-minute walk)

    3. Using filesystem tools, I've written the complete details including addresses, opening hours, price ranges, and recommended dishes to restaurant.txt in the current directory.

    All information has been saved successfully, and you'll find comprehensive recommendations for your Barcelona trip in the text file.
    """

    # Simulate writing the file (in a real implementation, this would be done by the agent)
    restaurant_info = """
    BARCELONA TRAVEL GUIDE

    YOUR ACCOMMODATION:
    Gothic Quarter Luxury Apartment
    ⭐ 4.9/5 (183 reviews)
    €175 per night
    Features: Air conditioning, Full kitchen, Washing machine, Balcony with city views
    Address: Carrer de Ferran, Gothic Quarter, Barcelona 08002

    NEARBY RESTAURANTS:

    1. El Xampanyet
    ⭐ 4.8/5
    Traditional Spanish tapas in a lively, authentic setting
    Known for: Anchovies, cava, and preserved seafood
    Price: €€
    Address: Carrer de Montcada, 22, 08003 Barcelona
    Hours: 12:00-15:30, 19:00-23:00, Closed Sundays
    Notes: No reservations, arrive early to avoid queues

    2. Bodega Biarritz
    ⭐ 4.7/5
    Modern tapas bar with creative small plates
    Known for: Patatas bravas, montaditos, and Spanish omelette
    Price: €€
    Address: Carrer del Vidre, 8, 08002 Barcelona
    Hours: 13:00-23:00 daily
    Notes: Small space, often busy

    3. Can Culleretes
    ⭐ 4.6/5
    Founded in 1786, the oldest restaurant in Barcelona
    Known for: Traditional Catalan cuisine and seafood
    Price: €€€
    Address: Carrer d'en Quintana, 5, 08002 Barcelona
    Hours: 13:30-16:00, 20:30-23:00, Closed Mondays
    Notes: Historic atmosphere, reservations recommended

    NEARBY ATTRACTIONS:

    1. Barcelona Cathedral
    ⭐ 4.7/5
    Gothic cathedral dating from the 13th-15th centuries
    Distance: 5-minute walk
    Hours: 8:00-19:30 daily, different hours on Sundays
    Notes: Free entry before 12:00 and after 17:00

    2. Picasso Museum
    ⭐ 4.6/5
    Houses one of the most extensive collections of Picasso's work
    Distance: 8-minute walk
    Hours: 10:00-20:00, Closed Mondays
    Notes: Free admission on Thursday evenings, book online to skip lines

    3. La Rambla
    ⭐ 4.5/5
    Famous tree-lined pedestrian street with shops and cafes
    Distance: 10-minute walk
    Notes: Best in early morning or evening, watch for pickpockets
    """

    File.write(Path.join(__DIR__, "restaurant.txt"), restaurant_info)

    IO.puts("\nResult: #{result}")

    IO.puts(
      "\nExample completed! A file named 'restaurant.txt' has been created in the examples directory."
    )
  end
end

# Run the example
MultiServerExample.run()
