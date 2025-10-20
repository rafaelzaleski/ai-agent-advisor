defmodule AiAgentAdvisor.Clients.HubspotClient do
  alias AiAgentAdvisor.Accounts
  alias AiAgentAdvisor.Accounts.User

  @base_url "https://api.hubapi.com"

  def list_contacts(%User{} = user) do
    with {:ok, client_with_token} <- get_authed_client(user) do
      case OAuth2.Client.get(client_with_token, @base_url <> "/crm/v3/objects/contacts?properties=firstname,lastname,email") do
        {:ok, %{body: %{"results" => contacts}}} ->
          {:ok, contacts}
        {:ok, %{body: %{}}} ->
          {:ok, []}
        {:error, reason} ->
          IO.inspect(reason, label: "Error listing HubSpot contacts")
          {:error, :api_error}
      end
    end
  end

  def get_contact_notes(%User{} = _user, contact_id) do
    IO.puts("Fetching notes for contact #{contact_id}...")
    {:ok, ["Note 1 for contact #{contact_id}", "Note 2 for contact #{contact_id}"]}
  end

  defp get_authed_client(%User{} = user) do
    expires_at_utc = DateTime.from_naive!(user.hubspot_token_expires_at, "Etc/UTC")

    is_expired =
      DateTime.compare(DateTime.utc_now() |> DateTime.add(60, :second), expires_at_utc) == :gt

    if is_expired do
      with {:ok, refreshed_token} <- refresh_hubspot_token(user) do
        {:ok, Map.put(build_base_client(), :token, refreshed_token)}
      end
    else
      token = %OAuth2.AccessToken{
        access_token: user.hubspot_access_token,
        refresh_token: user.hubspot_refresh_token,
        expires_at: DateTime.to_unix(expires_at_utc)
      }

      {:ok, Map.put(build_base_client(), :token, token)}
    end
  end

  defp refresh_hubspot_token(%User{} = user) do
    refresh_client =
      OAuth2.Client.new(
        strategy: OAuth2.Strategy.Refresh,
        client_id: System.get_env("HUBSPOT_CLIENT_ID"),
        client_secret: System.get_env("HUBSPOT_CLIENT_SECRET"),
        site: "https://api.hubapi.com",
        token_url: "/oauth/v1/token",
        params: %{"refresh_token" => user.hubspot_refresh_token}
      )

    case OAuth2.Client.get_token(refresh_client) do
      {:ok, client_with_new_token} ->
        new_token = client_with_new_token.token
        Accounts.update_hubspot_tokens(user, new_token)
        {:ok, new_token}

      {:error, reason} ->
        IO.inspect(reason, label: "Failed to refresh HubSpot token")
        {:error, reason}
    end
  end

  defp build_base_client() do
    OAuth2.Client.new(
      strategy: Ueberauth.Strategy.Hubspot.OAuth,
      client_id: System.get_env("HUBSPOT_CLIENT_ID"),
      client_secret: System.get_env("HUBSPOT_CLIENT_SECRET"),
      redirect_uri: "http://localhost:4000/auth/hubspot/callback"
    )
  end
end
