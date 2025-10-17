defmodule AiAgentAdvisor.Repo do
  use Ecto.Repo,
    otp_app: :ai_agent_advisor,
    adapter: Ecto.Adapters.Postgres
end
