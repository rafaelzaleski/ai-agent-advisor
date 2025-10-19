defmodule AiAgentAdvisor.Repo.Migrations.AddGoogleTokensToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :google_access_token, :binary
      add :google_refresh_token, :binary
      add :google_token_expires_at, :naive_datetime
    end
  end
end
