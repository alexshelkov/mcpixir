defmodule Mcpixir.LLMClient do
  @moduledoc """
  Client for interacting with LLM providers.
  
  This module defines the interface for LLM clients and provides
  basic implementation that delegates to provider-specific modules.
  """

  @type t :: %__MODULE__{
          provider: atom(),
          config: map()
        }

  defstruct [
    :provider,
    :config
  ]
  
  @doc """
  Creates a new LLM client with the given configuration.
  """
  @spec new(map()) :: {:ok, t()}
  def new(config) do
    provider = Map.get(config, :provider, :mock)
    
    llm_client = %__MODULE__{
      provider: provider,
      config: config
    }
    
    {:ok, llm_client}
  end
  
  @doc """
  Runs a query using the LLM client.
  """
  @spec run(t(), list()) :: {:ok, map()} | {:error, String.t()}
  def run(client, messages) do
    provider_module = get_provider_module(client.provider)
    
    if provider_module do
      provider_module.run(client, messages)
    else
      # Fallback when provider module isn't available
      {:ok, %{"role" => "assistant", "content" => "LLM integration is not available. Using placeholder response."}}
    end
  end
  
  # Private helper function to map provider to module
  defp get_provider_module(provider) do
    case provider do
      :openai -> 
        if Code.ensure_loaded?(Mcpixir.LLMClient.OpenAI), do: Mcpixir.LLMClient.OpenAI, else: nil
      
      :anthropic -> 
        if Code.ensure_loaded?(Mcpixir.LLMClient.Anthropic), do: Mcpixir.LLMClient.Anthropic, else: nil
        
      :langchain -> 
        if Code.ensure_loaded?(Mcpixir.LLMClient.LangChain), do: Mcpixir.LLMClient.LangChain, else: nil
      
      _ -> nil
    end
  end
end