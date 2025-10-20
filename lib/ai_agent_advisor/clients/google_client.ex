defmodule AiAgentAdvisor.Clients.GoogleClient do
  alias AiAgentAdvisor.Accounts
  alias AiAgentAdvisor.Accounts.User

  @base_url "https://gmail.googleapis.com/gmail/v1/users/me"

  def list_message_ids(%User{} = user) do
    with {:ok, client_with_token} <- get_authed_client(user) do
      case OAuth2.Client.get(client_with_token, @base_url <> "/messages?maxResults=100") do
        {:ok, %{body: %{"messages" => messages}}} ->
          ids = Enum.map(messages, & &1["id"])
          {:ok, ids}
        {:ok, %{body: %{}}} ->
          {:ok, []}
        {:error, reason} ->
          IO.inspect(reason, label: "Error listing Google messages")
          {:error, :api_error}
      end
    end
  end

  def get_message_content(%User{} = user, message_id) do
    with {:ok, client_with_token} <- get_authed_client(user) do
      case OAuth2.Client.get(client_with_token, @base_url <> "/messages/#{message_id}") do
        {:ok, %{body: %{"payload" => payload} = body}} ->
          base64_content = extract_plain_text_from_payload(payload)

          raw_content =
            if base64_content do
              Base.url_decode64(base64_content, padding: false)
              |> case do
                {:ok, decoded} -> decoded
                _ -> ""
              end
            else
              ""
            end

          headers = get_in(body, ["payload", "headers"])
          subject = find_header(headers, "Subject") || "No Subject"
          from = find_header(headers, "From") || "Unknown Sender"

          # Return a map with the structured data
          {:ok, %{subject: subject, from: from, body: raw_content}}
        {:error, reason} ->
          IO.inspect(reason, label: "Error getting message content for #{message_id}")
          {:error, :api_error}
      end
    end
  end

  defp find_header(headers, name) do
    (headers || [])
    |> Enum.find(&(&1["name"] == name))
    |> Map.get("value")
  end

  defp extract_plain_text_from_payload(payload) do
    IO.inspect(payload, label: "extract_plain_text_from_payload")
    plain_text_part =
      (payload["parts"] || [])
      |> Enum.find(&(&1["mimeType"] == "text/plain"))

    cond do
      plain_text_part ->
        plain_text_part |> get_in(["body", "data"])

      payload["mimeType"] == "text/plain" ->
        payload |> get_in(["body", "data"])

      true ->
        nil
    end
  end

  defp get_authed_client(%User{} = user) do
    expires_at_utc = DateTime.from_naive!(user.google_token_expires_at, "Etc/UTC")

    is_expired =
      DateTime.compare(DateTime.utc_now() |> DateTime.add(60, :second), expires_at_utc) == :gt

    if is_expired do
      # If the token is expired, we perform the full refresh flow,
      # which now returns a complete, configured client.
      refresh_google_token(user)
    else
      # Token is still valid, build the client and inject the token directly.
      # This path is correct as it uses the client from build_base_client.
      token = %OAuth2.AccessToken{
        access_token: user.google_access_token,
        refresh_token: user.google_refresh_token,
        expires_at: DateTime.to_unix(expires_at_utc)
      }

      {:ok, Map.put(build_base_client(), :token, token)}
    end
  end

  defp refresh_google_token(%User{} = user) do
    refresh_client =
      build_base_client()
      |> Map.put(:strategy, OAuth2.Strategy.Refresh)
      |> Map.put(:params, %{"refresh_token" => user.google_refresh_token})

    case OAuth2.Client.get_token(refresh_client) do
      {:ok, client_with_new_token} ->
        # The new token is inside the returned client struct.
        new_token = client_with_new_token.token
        Accounts.update_google_tokens(user, new_token)
        # Return the ENTIRE new client, which has the token and serializer.
        {:ok, client_with_new_token}

      {:error, reason} ->
        IO.inspect(reason, label: "Failed to refresh Google token")
        {:error, reason}
    end
  end

  defp build_base_client() do
    OAuth2.Client.new(
      strategy: Ueberauth.Strategy.Google.OAuth,
      client_id: System.get_env("GOOGLE_CLIENT_ID"),
      client_secret: System.get_env("GOOGLE_CLIENT_SECRET"),
      redirect_uri: "http://localhost:4000/auth/google/callback",
      site: "https://oauth2.googleapis.com",
      token_url: "/token"
    )
    # Add the serializer to the base client
    |> OAuth2.Client.put_serializer("application/json", Jason)
  end
end
