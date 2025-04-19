defmodule Mcpixir.TaskManagers.SSEManager do
  @moduledoc """
  Task manager that sends events using Server-Sent Events (SSE).
  """

  @behaviour Mcpixir.TaskManagers.Base

  defstruct [
    :url,
    :http_client,
    :config
  ]

  @impl Mcpixir.TaskManagers.Base
  def new(config) do
    url = Map.get(config, :url)

    if url == nil do
      {:error, "SSE URL not provided"}
    else
      {:ok, %__MODULE__{url: url, config: config}}
    end
  end

  @impl Mcpixir.TaskManagers.Base
  def start(manager) do
    # For SSE, we don't need to maintain a persistent connection
    # We'll just create a HTTP client to use for event sending
    {:ok, %{manager | http_client: HTTPoison}}
  end

  @impl Mcpixir.TaskManagers.Base
  def stop(_manager) do
    # Nothing to close for SSE
    :ok
  end

  @impl Mcpixir.TaskManagers.Base
  def send_event(manager, event_type, data) do
    event = %{
      type: event_type,
      data: data,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    json_event = Jason.encode!(event)
    sse_data = "event: #{event_type}\ndata: #{json_event}\n\n"

    headers = [
      {"Content-Type", "text/event-stream"},
      {"Cache-Control", "no-cache"}
    ]

    case HTTPoison.post(manager.url, sse_data, headers) do
      {:ok, %HTTPoison.Response{status_code: code}} when code in 200..299 ->
        :ok

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "HTTP error: #{code}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
