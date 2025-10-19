defmodule AiAgentAdvisor.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def up do
    create table(:documents) do
      add :content, :text, null: false
      add :embedding, :vector, size: 1536
      add :source, :string, null: false # e.g., "gmail", "hubspot"
      add :source_id, :string # e.g., the original email or note ID
      add :user_id, references(:users, on_delete: :delete_all, type: :string), null: false

      timestamps()
    end

    create index(:documents, [:user_id])

    # This is a special index for fast vector similarity searches, created with raw SQL
    execute("CREATE INDEX documents_embedding_index ON documents USING ivfflat (embedding vector_l2_ops)")
  end

  def down do
    execute("DROP INDEX documents_embedding_index")
    drop table(:documents)
  end
end
