defmodule AiAgentAdvisor.Ingestion do
  alias AiAgentAdvisor.Ingestion.Document
  alias AiAgentAdvisor.Repo

  @doc """
  Creates a new document in the database.
  """
  def create_document(attrs \\ %{}) do
    %Document{}
    |> Document.changeset(attrs)
    |> Repo.insert()
  end
end
