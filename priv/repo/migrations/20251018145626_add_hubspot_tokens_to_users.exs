defmodule AiAgentAdvisor.Repo.Migrations.AddHubspotTokensToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :hubspot_access_token, :binary
      add :hubspot_refresh_token, :binary
      add :hubspot_token_expires_at, :naive_datetime
    end
  end
end
