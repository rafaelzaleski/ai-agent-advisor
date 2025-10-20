defmodule AiAgentAdvisor.Ingestion.DataSyncWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  alias AiAgentAdvisor.Accounts
  alias AiAgentAdvisor.Accounts.User
  alias AiAgentAdvisor.Agent
  alias AiAgentAdvisor.Clients.{GoogleClient, HubspotClient}
  alias AiAgentAdvisor.Ingestion
  alias AiAgentAdvisor.Ingestion.Chunker

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    IO.inspect(user_id, label: "[DEBUG] Starting DataSyncWorker for user")

    case Accounts.get_user(user_id) do
      nil ->
        {:error, "User with id #{user_id} not found."}

      user ->
        # Run syncs for different sources in parallel
        tasks = [
          Task.async(fn -> sync_google_data(user) end),
          Task.async(fn -> sync_hubspot_data(user) end)
        ]

        Task.await_many(tasks, :infinity)
        IO.inspect(user_id, label: "[DEBUG] Finished DataSyncWorker for user")
        {:ok, "Data sync completed for user #{user_id}"}
    end
  end

  defp sync_google_data(%User{} = user) do
    IO.inspect(user.email, label: "[DEBUG] 1. Starting Google Sync")

    with {:ok, message_ids} <- GoogleClient.list_message_ids(user) do
      IO.inspect(message_ids, label: "[DEBUG] 2. Fetched Message IDs from Gmail API")

      message_ids
      |> Task.async_stream(
        fn message_id ->
          with {:ok, email_data} <- GoogleClient.get_message_content(user, message_id) do
            process_and_save_content(user, email_data, "gmail", message_id)
          end
        end,
        max_concurrency: 8,
        on_timeout: :kill_task
      )
      |> Enum.to_list()
    end
  end

  defp sync_hubspot_data(%User{hubspot_access_token: nil}), do: :ok
  defp sync_hubspot_data(%User{} = user) do
    with {:ok, contacts} <- HubspotClient.list_contacts(user) do
      contacts
      |> Task.async_stream(
        fn contact ->
          contact_id = contact["id"]
          contact_content =
            "HubSpot Contact: #{contact["properties"]["firstname"]} #{contact["properties"]["lastname"]}, Email: #{contact["properties"]["email"]}"
          process_and_save_content(user, contact_content, "hubspot", contact_id)

          with {:ok, notes} <- HubspotClient.get_contact_notes(user, contact_id) do
            Enum.each(notes, &process_and_save_content(user, &1, "hubspot_note", contact_id))
          end
        end,
        max_concurrency: 4
      )
      |> Enum.to_list()
    end
  end

  defp process_and_save_content(user, %{subject: subject, from: from, body: body}, "gmail", source_id) do
    full_content = "Subject: #{subject}\n\n#{body}"
    chunks = Chunker.split(full_content)
    metadata = %{from: from, subject: subject}

    chunks
    |> Task.async_stream(
      fn chunk ->
        with {:ok, embedding} <- Agent.embed_text(chunk) do
          Ingestion.create_document(%{
            user_id: user.id,
            content: chunk,
            embedding: embedding,
            source: "gmail",
            source_id: source_id,
            metadata: metadata
          })
        end
      end,
      max_concurrency: 8
    )
    |> Enum.to_list()
  end

  defp process_and_save_content(user, content, source, source_id)
    when is_binary(content) do
    chunks = Chunker.split(content)
    IO.inspect(Enum.map(chunks, &String.slice(&1, 0, 50)),
      label: "[DEBUG] 4. Split content into chunks"
    )

    chunks
    |> Task.async_stream(
      fn chunk ->
        case Agent.embed_text(chunk) do
          {:ok, embedding} ->
            IO.inspect(
              %{
                chunk: String.slice(chunk, 0, 50),
                embedding_preview: embedding |> Pgvector.to_list() |> Enum.take(3)
              },
              label: "[DEBUG] 5. Successfully embedded chunk"
            )

            result =
              Ingestion.create_document(%{
                user_id: user.id,
                content: chunk,
                embedding: embedding,
                source: source,
                source_id: source_id,
                metadata: %{}
              })

            IO.inspect(result, label: "[DEBUG] 6. Database insert result")

          {:error, reason} ->
            IO.inspect(reason, label: "[ERROR] Failed to embed chunk")
        end
      end,
      max_concurrency: 8
    )
    |> Enum.to_list()
  end
end
