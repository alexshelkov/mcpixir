defmodule Mcpixir.LLMClient.LangChain do
  @moduledoc """
  LangChain-specific implementation of the LLM client.
  
  This module handles using a pre-configured LangChain model instance
  that is provided directly by the user.
  """
  
  @behaviour Mcpixir.LLMClient.Base
  
  @impl true
  def run(client, messages) do
    if langchain_available?() do
      run_with_langchain(client, messages)
    else
      # Fallback if LangChain isn't available
      {:ok, %{"role" => "assistant", "content" => "LangChain library is not available."}}
    end
  end
  
  # Private functions
  
  defp run_with_langchain(client, messages) do
    # This is for when the user has pre-configured a LangChain instance
    langchain_llm = Map.get(client.config, :model)
    
    if is_nil(langchain_llm) do
      {:error, "LangChain LLM model not provided in configuration"}
    else
      module = langchain_module()
      
      if module do
        # Convert messages to LangChain format
        formatted_messages = format_messages_for_langchain(messages)
        
        # Run the model with the pre-configured LangChain instance
        try do
          result = apply(module, :call, [langchain_llm, formatted_messages, []])
          {:ok, %{"role" => "assistant", "content" => result.content}}
        rescue
          e ->
            {:error, "LangChain request failed: #{inspect(e)}"}
        catch
          :exit, reason ->
            {:error, "LangChain request exited: #{inspect(reason)}"}
        end
      else
        {:error, "LangChain.ChatModels module not available"}
      end
    end
  end
  
  defp langchain_available? do
    Mcpixir.Application.langchain_available?()
  end
  
  defp langchain_module do
    Mcpixir.Application.langchain_models_module()
  end
  
  defp format_messages_for_langchain(messages) do
    Mcpixir.Application.format_messages_for_langchain(messages)
  end
end