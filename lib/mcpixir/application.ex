defmodule Mcpixir.Application do
  @moduledoc """
  Application module for Mcpixir that handles LangChain integration and other application-level concerns.
  """

  use Application

  @impl true
  def start(_type, _args) do
    # Get the current environment
    env = Application.get_env(:mcpixir, :environment, :dev)
    
    # Start supervision tree with proper children
    opts = [strategy: :one_for_one, name: Mcpixir.Supervisor]
    
    # Start supervision tree
    children(env)
    |> Supervisor.start_link(opts)
  end
  
  # Define children for each environment
  defp children(env) do
    [
      # Core dependencies that should always be started
      {Mcpixir.ServerManager, []},
      {Registry, keys: :unique, name: Mcpixir.SessionRegistry}
    ] ++ maybe_add_langchain(env)
  end
  
  # Conditionally start LangChain in development and production
  defp maybe_add_langchain(env) when env in [:dev, :prod] do
    # Try to load LangChain and start any required services
    case Code.ensure_loaded?(LangChain) do
      true ->
        # Pre-load LangChain modules that will be used frequently
        _ = Code.ensure_loaded?(LangChain.Message)
        _ = Code.ensure_loaded?(LangChain.ChatModels)
        _ = Code.ensure_loaded?(LangChain.ChatModels.OpenAI)
        _ = Code.ensure_loaded?(LangChain.ChatModels.Anthropic)
        
        # We don't need to actually start any processes, just ensure modules are loaded
        []
        
      false ->
        # LangChain not available, which is fine as it's optional
        []
    end
  end
  
  # Don't load LangChain in test
  defp maybe_add_langchain(:test), do: []

  @doc """
  Load optional dependencies like LangChain
  
  Returns a boolean indicating whether LangChain is available.
  """
  def load_optional_dependencies do
    try do
      # Try to load LangChain module itself
      Code.ensure_loaded?(LangChain) and
        # Also verify some key modules are available
        Code.ensure_loaded?(LangChain.Message) and
        Code.ensure_loaded?(LangChain.ChatModels)
    rescue
      # Handle any loading errors gracefully
      _ -> false
    catch
      # Handle any unexpected issues
      _, _ -> false
    end
  end

  @doc """
  Checks if LangChain integration is available.
  Always use this function instead of directly checking Code.ensure_loaded.
  """
  def langchain_available? do
    # This is a hardcoded true because we've removed the optional flag 
    # from the dependency in mix.exs and are forcing it to be loaded in all mix tasks
    true
  end

  @doc """
  Gets the OpenAI module if available.
  """
  def openai_module do
    try do
      if langchain_available?() && Code.ensure_loaded?(LangChain.ChatModels.OpenAI) do
        LangChain.ChatModels.OpenAI
      else
        nil
      end
    rescue
      _ -> nil
    end
  end

  @doc """
  Gets the Anthropic module if available.
  """
  def anthropic_module do
    try do
      if langchain_available?() && Code.ensure_loaded?(LangChain.ChatModels.Anthropic) do
        LangChain.ChatModels.Anthropic
      else
        nil
      end
    rescue
      _ -> nil
    end
  end

  @doc """
  Gets the LangChain models module if available.
  """
  def langchain_models_module do
    try do
      if langchain_available?() do
        LangChain.ChatModels
      else
        nil
      end
    rescue
      _ -> nil
    end
  end

  @doc """
  Formats messages for LangChain integration.
  Safely handles the conversion, falling back to the original messages if LangChain is unavailable.
  """
  def format_messages_for_langchain(messages) do
    try do
      if langchain_available?() do
        Enum.map(messages, fn message ->
          role = Map.get(message, :role) || Map.get(message, "role", "user")
          content = Map.get(message, :content) || Map.get(message, "content", "")

          role_atom =
            case role do
              role when is_atom(role) -> role
              role when is_binary(role) -> String.to_atom(role)
              _ -> :user
            end

          # Create the struct dynamically to avoid compile-time errors when LangChain is missing
          struct(LangChain.Message, role: role_atom, content: content)
        end)
      else
        messages
      end
    rescue
      # Return original messages if any conversion fails
      _ -> messages
    catch
      _, _ -> messages
    end
  end
end