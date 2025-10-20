defmodule AiAgentAdvisor.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def up do
    create table(:documents, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :content, :text, null: false
      add :embedding, :vector, size: 1536
      add :source, :string, null: false
      add :source_id, :string
      add :user_id, references(:users, on_delete: :delete_all, type: :string), null: false

      timestamps()
    end

    create index(:documents, [:user_id])
    execute("CREATE INDEX documents_embedding_index ON documents USING ivfflat (embedding vector_l2_ops)")
  end

  def down do
    execute("DROP INDEX documents_embedding_index")
    drop table(:documents)
  end
end
