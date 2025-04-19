#!/usr/bin/env elixir
# Helper script to run examples properly using Mix.
# Usage: elixir run_example.exs examples/chat_example.exs

defmodule ExampleRunner do
  def run do
    # Check if an example file was provided
    example_file = case System.argv() do
      [path] -> path
      _ -> 
        IO.puts("Please provide an example file path.")
        IO.puts("Usage: elixir run_example.exs examples/chat_example.exs")
        System.halt(1)
    end

    # Make sure the file exists
    unless File.exists?(example_file) do
      IO.puts("Example file not found: #{example_file}")
      System.halt(1)
    end

    # Get the absolute path to the project directory
    project_dir = Path.expand(".", __DIR__)

    # Run the example using mix run
    System.cmd("mix", ["run", example_file], cd: project_dir, into: IO.stream(:stdio, :line))
  end
end

ExampleRunner.run()