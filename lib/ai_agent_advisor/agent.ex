defmodule AiAgentAdvisor.Agent do
  alias AiAgentAdvisor.Accounts.User
  alias AiAgentAdvisor.Ingestion.Document
  alias AiAgentAdvisor.Repo
  alias Pgvector

  alias Gemini.APIs.Coordinator
  alias Gemini.Types.Response.{EmbedContentResponse, GenerateContentResponse}

  import Ecto.Query
  import Pgvector.Ecto.Query

  @embedding_model "gemini-embedding-001"
  @chat_model "gemini-2.5-flash"

  @doc """
  The main entry point for asking the agent a question, now with history.
  """
  def ask(%User{} = user, question, history \\ []) do
    case classify_intent(question, history) do
      :search_documents ->
        with {:ok, query_vector} <- embed_text(question),
             context_documents <- find_relevant_documents(user, query_vector) do
          generate_completion(question, context_documents, history)
        end

      :simple_greeting ->
        generate_greeting(question)
    end
    |> handle_ask_result()
  end

  defp handle_ask_result({:ok, answer}), do: answer
  defp handle_ask_result({:error, reason}), do: IO.inspect(reason, label: "Error in Agent.ask") && "Sorry, I encountered an error."

  def embed_text(text) do
    case Coordinator.embed_content(
        text,
        model: @embedding_model,
        output_dimensionality: 1536
      ) do
      {:ok, response} ->
        values = EmbedContentResponse.get_values(response)
        {:ok, Pgvector.new(values)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp find_relevant_documents(%User{} = user, query_vector) do
    query =
      from(d in Document,
        where: d.user_id == ^user.id,
        order_by: [asc: l2_distance(d.embedding, ^query_vector)],
        limit: 5,
        select: d
      )

    Repo.all(query)
  end

  defp generate_completion(question, documents, history) do
    # Build a richer context string with metadata
    context_str =
      documents
      |> Enum.map(fn doc ->
        "Context from #{doc.metadata["source_type"] || doc.source} (From: #{doc.metadata["from"] || "N/A"}): \"#{doc.content}\""
      end)
      |> Enum.join("\n\n")

    system_prompt = """
    You are a helpful assistant for a financial advisor. Your user is asking a question.
    Based ONLY on the conversation history and the context provided below, answer the user's question.
    When you use information from the context, mention where it came from (e.g., "According to an email from John Doe...").
    Do not use any outside knowledge. If the answer is not in the context, say you don't know.
    """

    # Build the full conversation history for the AI model
    history_messages =
      history
      |> Enum.map(fn msg ->
        %{role: (if msg.role == :user, do: "user", else: "model"), parts: [%{text: msg.content}]}
      end)

    # Add the current question to the history
    final_messages = history_messages ++ [%{role: "user", parts: [%{text: "CONTEXT:\n#{context_str}\n\nQUESTION:\n#{question}"}]}]

    case Coordinator.generate_content(
           final_messages,
           model: @chat_model,
           system_instruction: %{parts: [%{text: system_prompt}]}
         ) do
      {:ok, response} -> {:ok, GenerateContentResponse.extract_text(response)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp classify_intent(question, history) do
    # For short, single-word messages with no history, assume it's a greeting.
    if length(String.split(question)) < 3 and history == [] do
      :simple_greeting
    else
      # Otherwise, assume we need to search.
      # A real implementation would use another LLM call for more accuracy.
      :search_documents
    end
  end

  # New function for simple, non-RAG responses
  defp generate_greeting(_question) do
    {:ok, "Hello! How can I help you find information in your documents today?"}
  end
end
