defmodule Mix.Tasks.Mcpixir do
  @moduledoc """
  Mcpixir example tasks demonstrating the library's capabilities.

  Mcpixir is an Elixir library to connect LLMs (Language Learning Models)
  to MCP (Machine Control Protocol) servers.

  ## Available Tasks

    * `mix mcpixir.chat`       - Runs a chat example with an LLM
    * `mix mcpixir.airbnb`     - Runs an Airbnb search example with an LLM
    * `mix mcpixir.blender`    - Runs a Blender 3D modeling example with an LLM
    * `mix mcpixir.browser`    - Runs a web browser automation example with an LLM
    * `mix mcpixir.filesystem` - Runs a filesystem interaction example with an LLM
    * `mix mcp.http`       - Runs an HTTP MCP server example with an LLM
    * `mix mcp.multi`      - Runs a multi-server example with an LLM

  ## API Keys

  To use these examples, you'll need valid API keys for either OpenAI or Anthropic.
  Set them in your environment variables:

  ```
  export OPENAI_API_KEY=your-openai-key
  export ANTHROPIC_API_KEY=your-anthropic-key
  ```

  ## Global Options

  Most tasks support these common options:

    * `--provider=[openai|anthropic]` - LLM provider to use
    * `--model=MODEL` - Specific LLM model to use
    * `--query=QUERY` - The query to send to the LLM

  ## Examples

  ```
  mix mcpixir               # Show this help
  mix mcpixir.chat          # Run chat example with OpenAI
  mix mcpixir.airbnb --provider=anthropic  # Run Airbnb example with Anthropic
  ```

  """
  use Mix.Task

  @shortdoc "Runs Mcpixir examples"

  @impl Mix.Task
  def run(_args) do
    IO.puts(IO.ANSI.bright() <> "MCP-Use Examples" <> IO.ANSI.reset())
    IO.puts("Elixir library for connecting LLMs to MCP servers\n")

    IO.puts("Available examples:")
    IO.puts("  mix mcpixir.chat       - Simple chat example")
    IO.puts("  mix mcpixir.airbnb     - Airbnb search")
    IO.puts("  mix mcpixir.blender    - Blender 3D modeling")
    IO.puts("  mix mcpixir.browser    - Web browser automation")
    IO.puts("  mix mcpixir.filesystem - Filesystem operations")
    IO.puts("  mix mcpixir.http       - HTTP server connection")
    IO.puts("  mix mcpixir.multi      - Multiple servers usage\n")

    IO.puts("For more details on each example:")
    IO.puts("  mix help mcpixir.chat\n")

    IO.puts("Most examples support common options:")
    IO.puts("  --provider=[openai|anthropic]  LLM provider")
    IO.puts("  --model=MODEL                  Specific model name")
    IO.puts("  --query=QUERY                  Query to send to the LLM\n")

    check_api_keys()
  end

  defp check_api_keys do
    openai_key = System.get_env("OPENAI_API_KEY")
    anthropic_key = System.get_env("ANTHROPIC_API_KEY")

    cond do
      is_nil(openai_key) && is_nil(anthropic_key) ->
        IO.puts(
          IO.ANSI.red() <>
            "Warning: No API keys found for OpenAI or Anthropic." <> IO.ANSI.reset()
        )

        IO.puts("To use these examples, set API keys in your environment:")
        IO.puts("  export OPENAI_API_KEY=your-openai-key")
        IO.puts("  export ANTHROPIC_API_KEY=your-anthropic-key")

      is_nil(openai_key) ->
        IO.puts(
          IO.ANSI.yellow() <>
            "Note: OPENAI_API_KEY not found. Examples will use Anthropic by default." <>
            IO.ANSI.reset()
        )

      is_nil(anthropic_key) ->
        IO.puts(
          IO.ANSI.yellow() <>
            "Note: ANTHROPIC_API_KEY not found. Examples will use OpenAI by default." <>
            IO.ANSI.reset()
        )

      true ->
        IO.puts(
          IO.ANSI.green() <>
            "Both OpenAI and Anthropic API keys are set. All examples should work." <>
            IO.ANSI.reset()
        )
    end
  end
end
