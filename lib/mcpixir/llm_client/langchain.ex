defmodule Mcpixir.LLMClient.LangChain do
  @moduledoc """
  LangChain-specific implementation of the LLM client.

  This module handles using a pre-configured LangChain model instance
  that is provided directly by the user.
  """

  @behaviour Mcpixir.LLMClient.Base

  @impl Mcpixir.LLMClient.Base
  def run(client, messages) do
    if langchain_available?() do
      run_with_langchain(client, messages)
    else
      # Fallback if LangChain isn't available
      {:ok,
       %{"role" => "assistant", "content" => "LangChain integration requires LangChain library."}}
    end
  end

  # Private functions

  defp run_with_langchain(client, messages) do
    with {:ok, LangChain} <- get_langchain_module(),
         {:ok, formatted_messages} <- format_messages(messages) do
      # This is for when the user has pre-configured a LangChain instance
      langchain_llm = Map.get(client.config, :model)

      if is_nil(langchain_llm) do
        {:error, "LangChain LLM model not provided in configuration"}
      else
        try do
          # Use the appropriate LangChain function based on the model type
          result = apply_langchain_model(langchain_llm, formatted_messages)
          {:ok, %{"role" => "assistant", "content" => result.content}}
        rescue
          e ->
            {:error, "LangChain request failed: #{inspect(e)}"}
        catch
          :exit, reason ->
            {:error, "LangChain request exited: #{inspect(reason)}"}
        end
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp apply_langchain_model(model, messages) do
    # Use the appropriate function based on the model type
    if function_exported?(model, :call, 3) do
      model.call(messages, [], [])
    else
      model.run(messages)
    end
  end

  defp get_langchain_module do
    Mcpixir.Application.get_langchain_module()
  end

  defp format_messages(messages) do
    {:ok, Mcpixir.Application.format_messages(messages)}
  end

  defp langchain_available? do
    Mcpixir.Application.langchain_available?()
  end
end
