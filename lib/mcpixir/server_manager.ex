defmodule Mcpixir.ServerManager do
  @moduledoc """
  Manages server connections and tool availability.
  """

  use GenServer

  @name __MODULE__

  @doc """
  Starts the server manager.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @doc """
  Registers a new server with the manager.
  """
  def register_server(name, config) do
    GenServer.call(@name, {:register_server, name, config})
  end

  @doc """
  Gets a list of servers that provide the requested tools.
  """
  def get_servers_for_tools(tools) do
    GenServer.call(@name, {:get_servers_for_tools, tools})
  end

  @doc """
  Registers available tools for a server.
  """
  def register_tools(server_name, tools) do
    GenServer.call(@name, {:register_tools, server_name, tools})
  end

  @doc """
  Lists available servers.
  """
  def list_servers do
    GenServer.call(@name, :list_servers)
  end

  # GenServer callbacks

  @impl true
  def init(_args) do
    state = %{
      servers: %{},
      server_tools: %{},
      tool_to_servers: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:register_server, name, config}, _from, state) do
    servers = Map.put(state.servers, name, config)
    server_tools = Map.put_new(state.server_tools, name, [])
    updated_state = %{state | servers: servers, server_tools: server_tools}

    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_call(:list_servers, _from, state) do
    {:reply, Map.keys(state.servers), state}
  end

  @impl true
  def handle_call({:register_tools, server_name, tools}, _from, state) do
    case Map.fetch(state.servers, server_name) do
      {:ok, _config} ->
        server_tools = Map.put(state.server_tools, server_name, tools)

        # Update the reverse lookup
        tool_to_servers =
          Enum.reduce(tools, state.tool_to_servers, fn tool, acc ->
            servers = Map.get(acc, tool, MapSet.new())
            Map.put(acc, tool, MapSet.put(servers, server_name))
          end)

        updated_state = %{state | server_tools: server_tools, tool_to_servers: tool_to_servers}
        {:reply, :ok, updated_state}

      :error ->
        {:reply, {:error, :server_not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_servers_for_tools, requested_tools}, _from, state) do
    # Find which tools are missing
    missing_tools =
      Enum.filter(requested_tools, fn tool ->
        not Map.has_key?(state.tool_to_servers, tool)
      end)

    if Enum.empty?(missing_tools) do
      # Find the minimal set of servers that cover all requested tools
      selected = select_minimal_servers(requested_tools, state.tool_to_servers)
      {:reply, {:ok, Enum.to_list(selected)}, state}
    else
      {:reply, {:error, {:missing_tools, missing_tools}}, state}
    end
  end

  defp select_minimal_servers(requested_tools, tool_to_servers) do
    # Simple greedy algorithm for server selection
    remaining_tools = MapSet.new(requested_tools)
    selected_servers = MapSet.new()

    select_servers_recurse(remaining_tools, tool_to_servers, selected_servers)
  end

  defp select_servers_recurse(remaining_tools, _tool_to_servers, selected_servers)
       when map_size(remaining_tools) == 0 do
    selected_servers
  end

  defp select_servers_recurse(remaining_tools, tool_to_servers, selected_servers) do
    # Find the server that covers most remaining tools
    choose_best_server_for_tools(remaining_tools, tool_to_servers, selected_servers)
  end

  # Extract the server choice logic to reduce nesting
  defp choose_best_server_for_tools(remaining_tools, tool_to_servers, selected_servers) do
    {best_server, _covered_count} = find_best_server(remaining_tools, tool_to_servers)

    # Add the best server and remove the covered tools
    new_selected = MapSet.put(selected_servers, best_server)

    # Get all tools provided by this server
    server_tools =
      Enum.filter(tool_to_servers, fn {_tool, servers} ->
        MapSet.member?(servers, best_server)
      end)
      |> Enum.map(fn {tool, _} -> tool end)
      |> MapSet.new()

    # Remove the covered tools
    new_remaining = MapSet.difference(remaining_tools, server_tools)

    select_servers_recurse(new_remaining, tool_to_servers, new_selected)
  end

  # Helper to find the best server for covering the most tools
  defp find_best_server(remaining_tools, tool_to_servers) do
    Enum.reduce(remaining_tools, {nil, 0}, fn tool, {best_server, max_count} ->
      servers = Map.get(tool_to_servers, tool, MapSet.new())

      find_server_with_most_coverage(
        servers,
        tool,
        remaining_tools,
        tool_to_servers,
        best_server,
        max_count
      )
    end)
  end

  defp find_server_with_most_coverage(
         servers,
         tool,
         remaining_tools,
         tool_to_servers,
         best_server,
         max_count
       ) do
    Enum.reduce(servers, {best_server, max_count}, fn server, {current_best, current_max} ->
      covered_tools = MapSet.new(Map.get(tool_to_servers, tool, []))
      covered_count = MapSet.intersection(remaining_tools, covered_tools) |> MapSet.size()

      if covered_count > current_max do
        {server, covered_count}
      else
        {current_best, current_max}
      end
    end)
  end
end
