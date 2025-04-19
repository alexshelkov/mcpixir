#!/usr/bin/env elixir
# Example demonstrating how to use mcp_use with Airbnb.
#
# This example shows how to connect an LLM to Airbnb through MCP tools
# to perform tasks like searching for accommodations.
#
# Special Thanks to https://github.com/openbnb-org/mcp-server-airbnb for the server.

# Make sure to run this from the project root:
# $ elixir examples/airbnb_use.exs

defmodule AirbnbExample do
  def run do
    IO.puts("Running Airbnb MCP Example")

    # Load Airbnb configuration
    config_path = Path.join(__DIR__, "airbnb_mcp.json")
    {:ok, config_data} = File.read(config_path)
    {:ok, config} = Jason.decode(config_data)

    # Extract the command and args for the Airbnb server
    airbnb_config = get_in(config, ["mcpServers", "airbnb"])
    command = "#{airbnb_config["command"]} #{Enum.join(airbnb_config["args"], " ")}"
    server_url = "stdio:#{command}"

    IO.puts("Connecting to Airbnb MCP server...")

    # Create the MCP client
    client =
      Mcpixir.new_client(%{
        servers: [server_url]
      })

    # Configure LLM (in a real implementation)
    # Here we're simulating the process
    llm_config = %{
      provider: :anthropic,
      model: "claude-3-5-sonnet"
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
    Find me a nice place to stay in Barcelona for 2 adults
    for a week in August. I prefer places with a pool and
    good reviews. Show me the top 3 options.
    """

    IO.puts("\nQuerying: #{query}")

    # Simulate search results
    results = [
      %{
        name: "Luxury Apartment with Pool near La Sagrada Familia",
        price: 210,
        per: "night",
        location: "Eixample, Barcelona",
        rating: 4.9,
        reviews: 187,
        features: ["Pool", "Air conditioning", "Kitchen", "Wifi", "Washer"]
      },
      %{
        name: "Beachfront Condo with Amazing Views",
        price: 245,
        per: "night",
        location: "Barceloneta, Barcelona",
        rating: 4.8,
        reviews: 203,
        features: ["Pool", "Beach access", "Balcony", "Wifi", "Parking"]
      },
      %{
        name: "Modern Penthouse with Rooftop Pool",
        price: 275,
        per: "night",
        location: "Gothic Quarter, Barcelona",
        rating: 4.95,
        reviews: 142,
        features: ["Rooftop pool", "Hot tub", "City views", "Gym", "Wifi"]
      }
    ]

    # Format and display results
    IO.puts("\nTop 3 Accommodations in Barcelona:")

    Enum.each(results, fn result ->
      IO.puts("\n#{result.name}")

      IO.puts(
        "#{result.location} | €#{result.price} per #{result.per} | Rating: #{result.rating}/5 (#{result.reviews} reviews)"
      )

      IO.puts("Features: #{Enum.join(result.features, ", ")}")
    end)

    IO.puts(
      "\nExample completed! In a real implementation, this would use actual Airbnb data via the MCP server."
    )
  end
end

# Create the airbnb_mcp.json file if it doesn't exist
config_path = Path.join(__DIR__, "airbnb_mcp.json")
airbnb_config = ~s({
  "mcpServers": {
      "airbnb": {
          "command": "npx",
          "args": ["-y", "@openbnb/mcp-server-airbnb", "--ignore-robots-txt"]
      }
  }
})

File.write(config_path, airbnb_config)

# Run the example
AirbnbExample.run()
