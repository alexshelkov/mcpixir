<picture>
  <img alt="" src="./static/image.png" width="600" style="background: transparent;">
</picture>

<h1 align="center">Unified MCP Client Library for Elixir</h1>

[![License](https://img.shields.io/github/license/ramonlimaramos/mcpixir)](https://github.com/ramonlimaramos/mcpixir/blob/main/LICENSE)
[![Elixir Version](https://img.shields.io/badge/elixir-v1.15%2B-blue)](https://elixir-lang.org/)
[![Hex.pm Version](https://img.shields.io/hexpm/v/mcpixir.svg)](https://hex.pm/packages/mcpixir)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dt/mcpixir.svg)](https://hex.pm/packages/mcpixir)

🌐 Mcpixir is the open source way to connect **any LLM to any MCP server** and build custom agents that have tool access, without using closed source or application clients.

💡 Let developers easily connect any LLM to tools like web browsing, file operations, and more.

# Features

## ✨ Key Features

| Feature                         | Description                                                                                            |
| ------------------------------- | ------------------------------------------------------------------------------------------------------ |
| 🔄 **Ease of use**              | Create your first MCP capable agent you need only 6 lines of code                                      |
| 🤖 **LLM Flexibility**          | Works with any LLM that supports tool calling (OpenAI, Anthropic, etc.)                                |
| 🌐 **HTTP Support**             | Direct connection to MCP servers running on specific HTTP ports                                        |
| ⚙️ **Dynamic Server Selection** | Agents can dynamically choose the most appropriate MCP server for a given task from the available pool |
| 🧩 **Multi-Server Support**     | Use multiple MCP servers simultaneously in a single agent                                              |
| 🛡️ **Tool Restrictions**        | Restrict potentially dangerous tools like file system or network access                                |

# Quick start

Add `mcpixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mcpixir, "~> 0.1.0"}
  ]
end
```

Or install from source:

```bash
git clone https://github.com/yourusername/mcpixir.git
cd mcpixir
mix deps.get
mix compile
```

### Configuring LLM Providers

Mcpixir works with various LLM providers. You'll need to configure your preferred LLM in your application. Add your API keys for the provider you want to use to your environment variables:

```bash
export OPENAI_API_KEY=your_openai_key_here
export ANTHROPIC_API_KEY=your_anthropic_key_here
```

> **Important**: Only models with tool calling capabilities can be used with Mcpixir. Make sure your chosen model supports function calling or tool use.

### Spin up your agent:

```elixir
# Create configuration dictionary
config = %{
  mcpServers: %{
    playwright: %{
      command: "npx",
      args: ["@playwright/mcp@latest"],
      env: %{
        DISPLAY: ":1"
      }
    }
  }
}

# Create MCP client from configuration dictionary
client = Mcpixir.new_client(config)

# Configure LLM
llm_config = %{
  provider: :openai,
  model: "gpt-4o"
}

# Create agent
{:ok, agent} = Mcpixir.new_agent(%{
  llm: llm_config,
  client: client
})

# Run the query
{:ok, result, updated_agent} = Mcpixir.run(agent, "Find the best restaurant in San Francisco")
IO.puts("\nResult: #{result}")
```

You can also add the servers configuration from a config file like this:

```elixir
config_path = Path.join("path/to", "browser_mcp.json")
{:ok, config_data} = File.read(config_path)
{:ok, config} = Jason.decode(config_data)

client = Mcpixir.new_client(config)
```

Example configuration file (`browser_mcp.json`):

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"],
      "env": {
        "DISPLAY": ":1"
      }
    }
  }
}
```

For other settings, models, and more, check out the documentation.

# Example Use Cases

## Web Browsing with Playwright

```elixir
# Create configuration
config = %{
  mcpServers: %{
    playwright: %{
      command: "npx",
      args: ["@playwright/mcp@latest"],
      env: %{
        DISPLAY: ":1"
      }
    }
  }
}

# Create the MCP client
client = Mcpixir.new_client(config)

# Configure LLM
llm_config = %{
  provider: :openai,
  model: "gpt-4o"
  # Alternative models:
  # provider: :anthropic, model: "claude-3-5-sonnet"
  # provider: :groq, model: "llama3-8b-8192"
}

# Create agent
{:ok, agent} = Mcpixir.new_agent(%{
  llm: llm_config,
  client: client
})

# Run the query
{:ok, result, updated_agent} = Mcpixir.run(agent, "Find the best restaurant in San Francisco USING GOOGLE SEARCH")
IO.puts("\nResult: #{result}")

# Ensure we clean up resources properly
Mcpixir.Client.stop_all_sessions(client)
```

## Airbnb Search

```elixir
# Create configuration with Airbnb
config = %{
  mcpServers: %{
    airbnb: %{
      command: "npx",
      args: ["-y", "@openbnb/mcp-server-airbnb", "--ignore-robots-txt"]
    }
  }
}

# Create the MCP client
client = Mcpixir.new_client(config)

# Configure LLM
llm_config = %{
  provider: :anthropic,
  model: "claude-3-5-sonnet"
}

# Create agent
{:ok, agent} = Mcpixir.new_agent(%{
  llm: llm_config,
  client: client
})

# Run a query to search for accommodations
query = """
Find me a nice place to stay in Barcelona for 2 adults
for a week in August. I prefer places with a pool and
good reviews. Show me the top 3 options.
"""

{:ok, result, updated_agent} = Mcpixir.run(agent, query)
IO.puts("\nResult: #{result}")

# Ensure we clean up resources properly
Mcpixir.Client.stop_all_sessions(client)
```

Example configuration file (`airbnb_mcp.json`):

```json
{
  "mcpServers": {
    "airbnb": {
      "command": "npx",
      "args": ["-y", "@openbnb/mcp-server-airbnb"]
    }
  }
}
```

## Blender 3D Creation

```elixir
# Create configuration with Blender
config = %{
  mcpServers: %{
    blender: %{
      command: "uvx",
      args: ["blender-mcp"]
    }
  }
}

# Create the MCP client
client = Mcpixir.new_client(config)

# Configure LLM
llm_config = %{
  provider: :anthropic,
  model: "claude-3-5-sonnet"
}

# Create agent
{:ok, agent} = Mcpixir.new_agent(%{
  llm: llm_config,
  client: client
})

# Run the query
{:ok, result, updated_agent} = Mcpixir.run(agent, "Create an inflatable cube with soft material and a plane as ground.")
IO.puts("\nResult: #{result}")

# Ensure we clean up resources properly
Mcpixir.Client.stop_all_sessions(client)
```

# Configuration Options

MCP-Use supports initialization from configuration files, making it easy to manage and switch between different MCP server setups:

```elixir
# Load configuration from file
config_path = Path.join("path/to", "mcp-config.json")
{:ok, config_data} = File.read(config_path)
{:ok, config} = Jason.decode(config_data)

# Create an MCP client from config
client = Mcpixir.new_client(config)

# Create and initialize a session
{:ok, client, session} = Mcpixir.Client.create_session(client, "http://localhost:8000")

# Use the session...

# Disconnect when done
Mcpixir.Client.stop_session(client, session.id)
```

## HTTP Connection Example

Mcpixir supports HTTP connections, allowing you to connect to MCP servers running on specific HTTP ports. This feature is particularly useful for integrating with web-based MCP servers.

Here's an example of how to use the HTTP connection feature:

```elixir
# Configuration with HTTP connection
config = %{
  mcpServers: %{
    http: %{
      url: "http://localhost:8931/sse"
    }
  }
}

# Create the MCP client
client = Mcpixir.new_client(config)

# Configure LLM
llm_config = %{
  provider: :openai,
  model: "gpt-4o"
}

# Create agent
{:ok, agent} = Mcpixir.new_agent(%{
  llm: llm_config,
  client: client
})

# Run the query
{:ok, result, updated_agent} = Mcpixir.run(agent, "Find the best restaurant in San Francisco USING GOOGLE SEARCH")
IO.puts("\nResult: #{result}")
```

This example demonstrates how to connect to an MCP server running on a specific HTTP port. Make sure to start your MCP server before running this example.

# Multi-Server Support

Mcpixir allows configuring and connecting to multiple MCP servers simultaneously using the `Mcpixir.Client`. This enables complex workflows that require tools from different servers, such as web browsing combined with file operations or 3D modeling.

## Configuration

You can configure multiple servers in your configuration file:

```json
{
  "mcpServers": {
    "airbnb": {
      "command": "npx",
      "args": ["-y", "@openbnb/mcp-server-airbnb", "--ignore-robots-txt"]
    },
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"],
      "env": {
        "DISPLAY": ":1"
      }
    }
  }
}
```

## Usage

The `Mcpixir.Client` module provides functions for managing connections to multiple servers. When creating an agent, you can provide a client configured with multiple servers.

By default, the agent will have access to tools from all configured servers. If you need to target a specific server for a particular task, you can specify the server parameters when creating the agent.

```elixir
# Create client with multiple servers
config = load_multi_server_config()
client = Mcpixir.new_client(config)

# Example: Running a query that may use tools from both servers
{:ok, agent} = Mcpixir.new_agent(%{
  llm: llm_config,
  client: client
})

# Query combining different capabilities
query = """
Search for a nice place to stay in Barcelona on Airbnb,
then use Google to find nearby restaurants and attractions.
"""

{:ok, result, _updated_agent} = Mcpixir.run(agent, query)
```

## Dynamic Server Selection (Server Manager)

For enhanced efficiency and to reduce potential agent confusion when dealing with many tools from different servers, you can leverage the built-in server manager functionality.

When enabled, the agent intelligently selects the correct MCP server based on the tool chosen by the LLM for a specific step. This minimizes unnecessary connections and ensures the agent uses the appropriate tools for the task.

```elixir
# Create client with multiple servers
config = load_multi_server_config()
client = Mcpixir.new_client(config)

# Create agent with server manager enabled
{:ok, agent} = Mcpixir.new_agent(%{
  llm: llm_config,
  client: client,
  use_server_manager: true  # Enable the Server Manager
})

# Run a query that uses tools from multiple servers
{:ok, result, _updated_agent} = Mcpixir.run(agent, """
  Search for a nice place to stay in Barcelona on Airbnb,
  then use Google to find nearby restaurants and attractions.
""")
```

# Tool Access Control

MCP-Use allows you to restrict which tools are available to the agent, providing better security and control over agent capabilities:

```elixir
# Create client
config = load_config()
client = Mcpixir.new_client(config)

# Create agent with restricted tools
{:ok, agent} = Mcpixir.new_agent(%{
  llm: llm_config,
  client: client,
  disallowed_tools: ["file_system", "network"]  # Restrict potentially dangerous tools
})

# Run a query with restricted tool access
{:ok, result, _updated_agent} = Mcpixir.run(agent, "Find the best restaurant in San Francisco")
```

# Running Examples

We provide a set of Mix tasks for demonstrating different aspects of the library. These tasks use real LLMs and MCP servers to showcase the full functionality.

## Mix Tasks

Run `mix mcp` to see all available examples:

```bash
mix mcpixir
```

Available examples:

- `mix mcpixir.chat` - Simple chat interaction with tools
- `mix mcpixir.airbnb` - Example showing integration with Airbnb
- `mix mcpixir.blender` - Example for controlling Blender 3D software
- `mix mcpixir.browser` - Web browsing with Playwright
- `mix mcpixir.filesystem` - Working with the filesystem
- `mix mcpixir.http` - HTTP connection to MCP servers
- `mix mcpixir.multi` - Using multiple MCP servers together

To get help on a specific example:

```bash
mix help mcpixir.chat
```

## Running Examples

Each example can be run with the following pattern:

```bash
# Basic usage
mix mcpixir.chat

# With options
mix mcpixir.browser --provider=anthropic --query="Find the top 5 Elixir packages on Hex.pm"
```

## Common Options

Most examples support these common options:

- `--provider=[openai|anthropic]` - LLM provider to use
- `--model=MODEL` - Specific LLM model to use
- `--query=QUERY` - The query to send to the LLM

## API Keys

These examples require API keys for OpenAI or Anthropic. Set them in your environment:

```bash
# For OpenAI
export OPENAI_API_KEY=your-openai-key

# For Anthropic
export ANTHROPIC_API_KEY=your-anthropic-key
```

# Debugging

Mcpixir provides built-in logging that helps diagnose issues in your agent implementation.

## Configuring Logging

There are several ways to configure logging:

### 1. Environment Variable

Set the log level using the `MCP_USE_LOG_LEVEL` environment variable:

```bash
export MCP_USE_LOG_LEVEL=debug  # Options: debug, info, warn, error
```

### 2. Setting Log Level Programmatically

You can set the log level directly in your code:

```elixir
# Set global log level
Mcpixir.Logging.set_level(:debug)  # Options: :debug, :info, :warning, :error
```

### 3. Configuration in mix.exs or config.exs

```elixir
# In config/config.exs
config :mcpixir,
  log_level: :debug
```

# Roadmap

- [x] Multiple Servers at once
- [x] Test remote connectors (http, ws)
- [ ] ...

# Contributing

We love contributions! Feel free to open issues for bugs or feature requests.

# Requirements

- Elixir 1.15+
- Erlang/OTP 25+
- MCP implementation (like Playwright MCP)
- LLM API access (OpenAI, Anthropic, etc.)

# Contributing

## Development Process

We welcome contributions to make this project better! Here are some steps to get started:

```bash
# Clone the repository
git clone https://github.com/yourusername/mcp-use-elixir.git
cd mcp-use-elixir

# Install dependencies
mix deps.get

# Run tests
mix test

# Run the code formatter
mix format

# Run the linter
mix credo
```

## Release Process

This project follows semantic versioning and uses a structured release process. You can release a new version using either:

### Using the Mix task

```bash
mix mcp.release 0.2.0
```

### Using the shell script

```bash
./bin/release.sh 0.2.0
```

Both methods will:

1. Check if the working directory is clean
2. Update the version in mix.exs
3. Update the CHANGELOG.md with the new version
4. Run tests to ensure everything works
5. Compile documentation
6. Create a git commit and tag
7. Publish to Hex.pm

# License

MIT
