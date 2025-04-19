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
    # Try to load LangChain module itself
    # Also verify some key modules are available
    Code.ensure_loaded?(LangChain) and
      Code.ensure_loaded?(LangChain.Message) and
      Code.ensure_loaded?(LangChain.ChatModels)
  rescue
    # Handle any loading errors gracefully
    _ -> false
  catch
    # Handle any unexpected issues
    _, _ -> false
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
  def get_openai_module do
    if langchain_available?() do
      {:ok, LangChain.ChatModels.ChatOpenAI}
    else
      {:error, "LangChain library is not available"}
    end
  end

  @doc """
  Gets the Anthropic module if available.
  """
  def get_anthropic_module do
    if langchain_available?() do
      {:ok, LangChain.ChatModels.ChatAnthropic}
    else
      {:error, "LangChain library is not available"}
    end
  end

  @doc """
  Gets the LangChain models module if available.
  """
  def get_langchain_module do
    if langchain_available?() do
      {:ok, LangChain}
    else
      {:error, "LangChain library is not available"}
    end
  end

  @doc """
  Formats messages for LangChain integration.
  Safely handles the conversion, falling back to the original messages if LangChain is unavailable.
  """
  def format_messages(messages) do
    if langchain_available?() do
      Enum.map(messages, &format_single_message/1)
    else
      messages
    end
  end

  defp format_single_message(message) do
    role = Map.get(message, :role) || Map.get(message, "role", "user")
    content = Map.get(message, :content) || Map.get(message, "content", "")

    case to_string(role) do
      "system" -> LangChain.Message.new_system!(content)
      "assistant" -> LangChain.Message.new_assistant!(content)
      _ -> LangChain.Message.new_user!(content)
    end
  end
end
