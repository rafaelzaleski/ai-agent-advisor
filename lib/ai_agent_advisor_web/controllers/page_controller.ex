defmodule AiAgentAdvisorWeb.PageController do
  use AiAgentAdvisorWeb, :controller

  def home(conn, _params) do
    if conn.assigns.current_user do
      redirect(conn, to: ~p"/settings")
    else
      render(conn, :home)
    end
  end
end
