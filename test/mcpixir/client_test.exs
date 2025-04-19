defmodule Mcpixir.ClientTest do
  use ExUnit.Case

  alias Mcpixir.Client

  test "new/1 creates a client with default config" do
    client = Client.new()
    assert is_map(client)
    assert is_map(client.config)
  end

  test "new/1 creates a client with custom config" do
    config = %{
      servers: ["http://example.com"],
      log_level: :debug
    }

    client = Client.new(config)
    assert is_map(client)
    assert is_map(client.config)
    assert client.config.servers == ["http://example.com"]
    assert client.config.log_level == :debug
  end
end
