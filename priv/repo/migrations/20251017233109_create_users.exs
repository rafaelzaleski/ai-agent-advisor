defmodule AiAgentAdvisor.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :string, primary_key: true
      add :email, :string, null: false
      add :provider, :string, null: false

      timestamps()
    end

    create index(:users, [:provider, :id], unique: true)
  end
end
