defmodule AiAgentAdvisor.Ingestion.Chunker do
  @doc """
  Splits a large block of text into smaller chunks.

  This is a basic implementation that splits by double newlines (paragraphs).
  A more advanced version could use token-based splitting or recursive splitting
  to ensure chunks are under a certain size.
  """
  def split(text) when is_binary(text) do
    text
    |> String.split("\n\n", trim: true)
    |> Enum.reject(&(&1 == ""))
  end
end
