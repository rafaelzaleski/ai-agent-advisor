defmodule AiAgentAdvisor.Ingestion.DataSyncWorker do
  use Oban.Worker, queue: :default

  alias AiAgentAdvisor.Accounts
  alias AiAgentAdvisor.Clients.{GoogleClient, HubspotClient}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    # 1. Fetch the user from the database
    case Accounts.get_user(user_id) do
      nil ->
        # User might have been deleted since the job was scheduled.
        # This is a safe way to exit.
        {:error, "User with id #{user_id} not found."}

      user ->
        # 2. Sync data from all connected sources
        sync_google_data(user)
        sync_hubspot_data(user)
        {:ok, "Data sync completed for user #{user_id}"}
    end
  end

  defp sync_google_data(%Accounts.User{} = user) do
    # For now, we just call the placeholder function.
    # Later, this will handle pagination and fetching full content.
    with {:ok, email_ids} <- GoogleClient.list_emails(user) do
      IO.inspect(email_ids, label: "Synced Google Email IDs")
      :ok
    end
  end

  # If the user hasn't connected HubSpot, we don't try to sync.
  defp sync_hubspot_data(%Accounts.User{hubspot_access_token: nil}), do: :ok
  defp sync_hubspot_data(%Accounts.User{} = user) do
    with {:ok, contact_ids} <- HubspotClient.list_contacts(user) do
      IO.inspect(contact_ids, label: "Synced HubSpot Contact IDs")
      :ok
    end
  end
end
