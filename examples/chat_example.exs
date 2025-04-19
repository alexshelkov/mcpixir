#!/usr/bin/env elixir
# Example script showing basic usage of the MCP-Use library

# Make sure to run this from the project root:
# $ elixir examples/chat_example.exs

# When running with `mix run`, all dependencies and modules are properly loaded.
# See README.md for instructions on how to run examples.

# Here we're using a mock LLM since we're not actually connecting to an LLM provider
defmodule MockLLM do
  def complete(messages) do
    system_msg = Enum.find(messages, fn msg -> msg.role == "system" end)
    user_msg = Enum.find(messages, fn msg -> msg.role == "user" end)

    IO.puts("\nSystem prompt: #{String.slice(system_msg.content, 0, 100)}...\n")
    IO.puts("User message: #{user_msg.content}\n")

    # Check if there's a tool call in the user message
    if String.contains?(user_msg.content, "weather") do
      %{
        role: "assistant",
        content: nil,
        tool_calls: [
          %{
            id: "call_1",
            type: "function",
            function: %{
              name: "get_weather",
              arguments: Jason.encode!(%{location: "San Francisco"})
            }
          }
        ]
      }
    else
      %{
        role: "assistant",
        content:
          "I'm a simulated LLM response. I can help answer questions or use tools when needed."
      }
    end
  end
end

# Add a mock function to run the example without actual dependencies
defmodule Mcpixir.Example do
  def run do
    IO.puts("MCP-Use Elixir Chat Example\n")

    # Create configuration
    config = %{
      servers: ["http://localhost:3000"],
      llm: %{provider: :mock},
      log_level: :info
    }

    IO.puts("Creating MCP agent...")

    # In a real implementation, you would use Mcpixir.new_agent(config)
    # Here we're simulating the agent creation
    agent = %{
      config: config,
      tools: [
        %{
          "name" => "get_weather",
          "description" => "Get weather information for a location",
          "parameters" => %{
            "type" => "object",
            "properties" => %{
              "location" => %{
                "type" => "string",
                "description" => "The location to get weather for"
              }
            },
            "required" => ["location"]
          }
        }
      ]
    }

    IO.puts("MCP agent created with #{length(agent.tools)} tools available\n")

    # Simulate a conversation
    user_input = "What's the weather like in San Francisco?"
    IO.puts("User: #{user_input}")

    # Create messages for the LLM
    messages = [
      %{role: "system", content: "You are a helpful assistant with access to tools."},
      %{role: "user", content: user_input}
    ]

    # Get response from mock LLM
    response = MockLLM.complete(messages)

    # Handle tool calls if present
    if Map.has_key?(response, :tool_calls) do
      IO.puts("Assistant: I'll check the weather for you.")

      # Simulate tool execution
      tool_call = List.first(response.tool_calls)
      IO.puts("\nExecuting tool: #{tool_call.function.name}")
      arguments = Jason.decode!(tool_call.function.arguments)
      IO.puts("Arguments: #{inspect(arguments)}")

      # Simulate tool result
      tool_result = %{
        "temperature" => 68,
        "condition" => "Partly Cloudy",
        "humidity" => 75
      }

      IO.puts("Tool result: #{inspect(tool_result)}")

      # Add tool result to messages
      updated_messages =
        messages ++
          [
            response,
            %{
              role: "tool",
              tool_call_id: tool_call.id,
              name: tool_call.function.name,
              content: Jason.encode!(tool_result)
            }
          ]

      # Get final response from LLM
      final_response = %{
        role: "assistant",
        content:
          "The weather in San Francisco is currently 68°F and partly cloudy with 75% humidity."
      }

      IO.puts("\nAssistant: #{final_response.content}")
    else
      IO.puts("Assistant: #{response.content}")
    end
  end
end

# Run the example
Mcpixir.Example.run()
