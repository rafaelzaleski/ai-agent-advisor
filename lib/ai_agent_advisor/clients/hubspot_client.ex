defmodule AiAgentAdvisor.Clients.HubspotClient do
  alias AiAgentAdvisor.Accounts.User

  @base_url "https://api.hubapi.com/"

  @doc """
  Fetches a list of contacts for a given user.
  This is a placeholder and will be fully implemented later.
  """
  def list_contacts(%User{} = user) do
    # Logic will be very similar to the Google client:
    # 1. Build authenticated client with token refresh.
    # 2. Make request to HubSpot contacts endpoint.
    # 3. Parse and return contacts.

    IO.puts("Fetching HubSpot contacts for user #{user.id}...")
    {:ok, ["contact_1", "contact_2"]}
  end

  @doc """
  Fetches the notes for a single contact.
  """
  def get_contact_notes(%User{} = user, contact_id) do
    IO.puts("Fetching notes for contact #{contact_id}...")
    {:ok, ["Note 1 for #{contact_id}", "Note 2 for #{contact_id}"]}
  end
end
