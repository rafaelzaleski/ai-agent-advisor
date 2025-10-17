defmodule AiAgentAdvisorWeb.PageController do
  use AiAgentAdvisorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
