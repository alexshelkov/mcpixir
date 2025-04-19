defmodule Mcpixir.LLMClient.OpenAI do
  @moduledoc """
  OpenAI-specific implementation of the LLM client.

  This module handles communication with OpenAI's API, using
  the LangChain library with support for tool calling.
  """

  @behaviour Mcpixir.LLMClient.Base

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Message

  @impl Mcpixir.LLMClient.Base
  def run(client, messages) do
    if langchain_available?() do
      run_with_langchain(client, messages)
    else
      # Fallback if LangChain isn't available
      {:ok,
       %{"role" => "assistant", "content" => "OpenAI integration requires LangChain library."}}
    end
  end

  defp run_with_langchain(client, messages) do
    model = Map.get(client.config, :model, "gpt-4o")
    api_key = System.get_env("OPENAI_API_KEY")

    llm =
      ChatOpenAI.new!(%{
        model: model,
        api_key: api_key,
        temperature: 0.7
      })

    chain =
      LLMChain.new!(%{
        llm: llm,
        verbose: false
      })

    chain_with_messages = add_messages_to_chain(chain, messages)

    case LLMChain.run(chain_with_messages, mode: :while_needs_response) do
      {:ok, _updated_chain, [message | _]} ->
        {:ok, %{"role" => "assistant", "content" => message.content}}

      {:ok, _updated_chain, message} ->
        {:ok, %{"role" => "assistant", "content" => message.content}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp add_messages_to_chain(chain, messages) do
    Enum.reduce(messages, chain, fn message, acc_chain ->
      role = Map.get(message, :role) || Map.get(message, "role", "user")
      content = Map.get(message, :content) || Map.get(message, "content", "")

      langchain_message =
        case to_string(role) do
          "system" -> Message.new_system!(content)
          "assistant" -> Message.new_assistant!(content)
          _ -> Message.new_user!(content)
        end

      LangChain.Chains.LLMChain.add_message(acc_chain, langchain_message)
    end)
  end

  defp langchain_available? do
    Mcpixir.Application.langchain_available?()
  end
end
