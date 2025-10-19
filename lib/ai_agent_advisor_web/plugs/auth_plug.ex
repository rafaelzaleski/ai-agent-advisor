defmodule AiAgentAdvisorWeb.AuthPlug do
  import Plug.Conn
  use Phoenix.VerifiedRoutes, router: AiAgentAdvisorWeb.Router, endpoint: AiAgentAdvisorWeb.Endpoint

  alias AiAgentAdvisor.Accounts

  @doc """
  This plug is called on every request.

  It checks the session for a user_id and assigns the
  current_user to the conn. If no user is logged in,
  the current_user is assigned to nil.
  """
  def fetch_current_user(conn, _opts) do
    with user_id when not is_nil(user_id) <- get_session(conn, :user_id),
         %AiAgentAdvisor.Accounts.User{} = user <- Accounts.get_user(user_id) do
      assign(conn, :current_user, user)
    else
      _ ->
        assign(conn, :current_user, nil)
    end
  end

  @doc """
  This plug requires a user to be authenticated.

  If the user is not authenticated (i.e., current_user is nil),
  it halts the connection and redirects to the home page.
  """
  def require_auth(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> clear_session()
      |> Phoenix.Controller.redirect(to: ~p"/")
      |> halt()
    end
  end
end
