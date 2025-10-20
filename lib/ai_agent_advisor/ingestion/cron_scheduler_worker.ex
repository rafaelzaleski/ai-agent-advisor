defmodule AiAgentAdvisor.Ingestion.CronSchedulerWorker do
  use Oban.Worker, queue: :scheduled

  alias AiAgentAdvisor.Accounts
  alias AiAgentAdvisor.Ingestion.DataSyncWorker

  @impl Oban.Worker
  def perform(_job) do
    user_ids = Accounts.list_all_user_ids()

    # Create a unique DataSyncWorker job for each user
    jobs =
      Enum.map(user_ids, fn user_id ->
        DataSyncWorker.new(%{user_id: user_id}, schedule_in: :rand.uniform(60))
      end)

    Oban.insert_all(jobs)

    :ok
  end
end
