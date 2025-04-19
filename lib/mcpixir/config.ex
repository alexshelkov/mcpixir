defmodule Mcpixir.Config do
  @moduledoc """
  Configuration types and utilities for MCP.
  """

  @type t :: %__MODULE__{
          llm: map(),
          tools: [String.t()],
          timeout: integer()
        }

  defstruct llm: %{},
            tools: [],
            timeout: 30_000

  @default_config %{
    servers: [],
    sessions: %{
      timeout: 30_000
    },
    log_level: :info
  }

  @doc """
  Loads configuration from file and/or provided map.
  """
  def load(config \\ %{}) do
    config_from_file = load_from_file()

    @default_config
    |> deep_merge(config_from_file)
    |> deep_merge(config)
  end

  @doc """
  Gets the connector type for a server URL.
  """
  def get_connector_type(url) do
    cond do
      String.starts_with?(url, "http") -> :http
      String.starts_with?(url, "ws") -> :websocket
      String.starts_with?(url, "stdio:") -> :stdio
      true -> :unknown
    end
  end

  # Private functions

  defp load_from_file do
    paths = [
      Path.join(System.user_home(), ".mcpixir.json"),
      Path.join(File.cwd!(), "mcpixir.json")
    ]

    Enum.find_value(paths, %{}, fn path ->
      read_config_file(path)
    end)
  end
  defp read_config_file(path) do
    with {:ok, content} <- File.read(path),
         {:ok, config} <- Jason.decode(content) do
      config
    else
      _ -> nil
    end
  end

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _k, l, r ->
      if is_map(l) and is_map(r) do
        deep_merge(l, r)
      else
        r
      end
    end)
  end

  defp deep_merge(_left, right), do: right
end
