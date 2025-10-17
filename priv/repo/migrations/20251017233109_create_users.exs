defmodule AiAgentAdvisor.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :name, :string
      add :provider, :string
      add :provider_id, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:provider, :provider_id])
    create unique_index(:users, [:email])
  end
end
