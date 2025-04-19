#!/usr/bin/env elixir
# Blender MCP example for mcp_use.
#
# This example demonstrates how to use the mcp_use library with MCPClient
# to connect an LLM to Blender through MCP tools via WebSocket.
# The example assumes you have installed the Blender MCP addon from:
# https://github.com/ahujasid/blender-mcp
#
# Make sure the addon is enabled in Blender preferences and the WebSocket
# server is running before executing this script.
#
# Special thanks to https://github.com/ahujasid/blender-mcp for the server.

# Make sure to run this from the project root:
# $ elixir examples/blender_use.exs

defmodule BlenderExample do
  def run do
    IO.puts("Running Blender MCP Example")

    # Create MCPClient with Blender MCP configuration
    config = %{
      mcpServers: %{
        blender: %{
          command: "uvx",
          args: ["blender-mcp"]
        }
      }
    }

    # Extract the command and args for the Blender server
    command =
      "#{config.mcpServers.blender.command} #{Enum.join(config.mcpServers.blender.args, " ")}"

    server_url = "stdio:#{command}"

    IO.puts("Connecting to Blender MCP server...")

    # Create the MCP client
    client =
      Mcpixir.new_client(%{
        servers: [server_url]
      })

    # Configure LLM (in a real implementation)
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
    query = "Create an inflatable cube with soft material and a plane as ground."

    IO.puts("\nQuerying: #{query}")

    # Simulate the agent's steps
    IO.puts("\nExecuting steps:")
    IO.puts("1. Creating a new Blender scene...")
    IO.puts("2. Adding a plane as ground...")
    IO.puts("3. Adding a cube...")
    IO.puts("4. Applying soft body physics to the cube...")
    IO.puts("5. Setting up material properties for the cube...")
    IO.puts("6. Setting up animation parameters...")

    # Simulate the result
    result = """
    I've created an inflatable cube with soft body physics on a ground plane:

    1. Added a ground plane at the origin and scaled it to 10x10
    2. Added a cube and positioned it 2 units above the ground
    3. Applied soft body physics to the cube with:
       - Soft Body Edge stiffness: 0.1
       - Soft Body Goal settings: 0.5 strength
       - Air pressure set to 1.0 to create inflation effect
    4. Added a semi-transparent material to the cube with:
       - Base color: Light blue
       - Transmission: 0.8
       - Roughness: 0.1

    The simulation is set to start at frame 1 and the cube will bounce and deform when it hits the ground plane. You can press Alt+A to see the animation.
    """

    IO.puts("\nResult: #{result}")

    IO.puts(
      "\nExample completed! In a real implementation, this would control Blender via the MCP server."
    )
  end
end

# Run the example
BlenderExample.run()
