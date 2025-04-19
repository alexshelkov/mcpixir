defmodule Mcpixir.Client do
  @moduledoc """
  Client for managing MCP connections and sessions.
  """

  @type t :: %__MODULE__{
          config: map()
        }

  alias Mcpixir.ServerManager
  alias Mcpixir.Session

  defstruct [
    :config,
    sessions: %{}
  ]

  @doc """
  Creates a new client with the given configuration.
  """
  def new(config \\ %{}) do
    %__MODULE__{config: config}
  end

  @doc """
  Creates a new session with the given server URL.
  """
  def create_session(client, server_url, opts \\ []) do
    session_config = Map.get(client.config, :sessions, %{})
    session_id = Keyword.get(opts, :session_id, Uniq.UUID.uuid7())

    case Session.start(server_url, session_config, session_id) do
      {:ok, session} ->
        updated_sessions = Map.put(client.sessions, session_id, session)
        {:ok, %{client | sessions: updated_sessions}, session}

      error ->
        error
    end
  end

  @doc """
  Gets all available tools.
  """
  def get_tools(client) do
    client.sessions
    |> Enum.map(fn {_id, session} -> Session.get_tools(session) end)
    |> List.flatten()
  end

  @doc """
  Gets a session by its ID.
  """
  def get_session(client, session_id) do
    Map.get(client.sessions, session_id)
  end

  @doc """
  Stops a session.
  """
  def stop_session(client, session_id) do
    case Map.fetch(client.sessions, session_id) do
      {:ok, session} ->
        Session.stop(session)
        updated_sessions = Map.delete(client.sessions, session_id)
        {:ok, %{client | sessions: updated_sessions}}

      :error ->
        {:error, :session_not_found}
    end
  end

  @doc """
  Stops all sessions.
  """
  def stop_all_sessions({:ok, client}) do
    Enum.each(client.sessions, fn {_id, session} -> Session.stop(session) end)
    {:ok, %{client | sessions: %{}}}
  end

  def stop_all_sessions(error), do: error

  @doc """
  Creates sessions for the specified tools.
  """
  def create_sessions_for_tools(client, tools) do
    with {:ok, servers} <- ServerManager.get_servers_for_tools(tools) do
      {new_client, sessions} =
        Enum.reduce(servers, {client, []}, fn server_url, {acc_client, acc_sessions} ->
          case create_session(acc_client, server_url) do
            {:ok, updated_client, session} ->
              {updated_client, [session | acc_sessions]}

            _error ->
              {acc_client, acc_sessions}
          end
        end)

      {:ok, new_client, sessions}
    end
  end
end
