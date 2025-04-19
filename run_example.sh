#!/bin/bash
# Helper script to run examples properly using Mix.
# Usage: ./run_example.sh examples/chat_example.exs

if [ $# -eq 0 ]; then
  echo "Please provide an example file path."
  echo "Usage: ./run_example.sh examples/chat_example.exs"
  exit 1
fi

EXAMPLE_FILE=$1

if [ ! -f "$EXAMPLE_FILE" ]; then
  echo "Example file not found: $EXAMPLE_FILE"
  exit 1
fi

# Run the example using mix run
cd "$(dirname "$0")" && mix run "$EXAMPLE_FILE"