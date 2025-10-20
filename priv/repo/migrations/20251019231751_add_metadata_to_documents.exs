defmodule AiAgentAdvisor.Repo.Migrations.AddMetadataToDocuments do
  use Ecto.Migration

  def change do
    alter table(:documents) do
      add :metadata, :map, default: %{}
    end
  end
end
