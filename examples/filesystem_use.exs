#!/usr/bin/env elixir
# Basic usage example for mcp_use.
#
# This example demonstrates how to use the mcp_use library with MCPClient
# to connect any LLM to MCP tools through a unified interface.
#
# Special Thanks to https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem
# for the server.

# Make sure to run this from the project root:
# $ elixir examples/filesystem_use.exs

defmodule FilesystemExample do
  def run do
    IO.puts("Running Filesystem MCP Example")

    # Create filesystem configuration
    config = %{
      mcpServers: %{
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

    # Extract the command and args for the Filesystem server
    command =
      "#{config.mcpServers.filesystem.command} #{Enum.join(config.mcpServers.filesystem.args, " ")}"

    server_url = "stdio:#{command}"

    IO.puts("Connecting to Filesystem MCP server...")

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
    query = "Hello can you give me a list of files and directories in the current directory"

    IO.puts("\nQuerying: #{query}")

    # Simulate the agent's steps
    IO.puts("\nExecuting steps:")
    IO.puts("1. Connecting to filesystem server...")
    IO.puts("2. Getting list of files in current directory...")

    # Get actual directory listing for more realistic example
    {:ok, files} = File.ls()

    # Format the files list
    formatted_files =
      files
      |> Enum.sort()
      |> Enum.map(fn file ->
        is_dir = File.dir?(file)
        if is_dir, do: "📁 #{file}/", else: "📄 #{file}"
      end)
      |> Enum.join("\n")

    # Simulate the result
    result = """
    Here's the list of files and directories in the current directory:

    #{formatted_files}
    """

    IO.puts("\nResult: #{result}")

    IO.puts(
      "\nExample completed! In a real implementation, this would use the MCP filesystem server."
    )
  end
end

# Run the example
FilesystemExample.run()
