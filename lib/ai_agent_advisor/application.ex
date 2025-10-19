defmodule AiAgentAdvisor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AiAgentAdvisorWeb.Telemetry,
      AiAgentAdvisor.Repo,
      {DNSCluster, query: Application.get_env(:ai_agent_advisor, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AiAgentAdvisor.PubSub},
      {Finch, name: AiAgentAdvisor.Finch},
      # Start a worker by calling: AiAgentAdvisor.Worker.start_link(arg)
      # {AiAgentAdvisor.Worker, arg},
      # Start to serve requests, typically the last entry
      AiAgentAdvisorWeb.Endpoint,
      AiAgentAdvisor.Vault,
      {Oban, Application.fetch_env!(:ai_agent_advisor, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AiAgentAdvisor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AiAgentAdvisorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
