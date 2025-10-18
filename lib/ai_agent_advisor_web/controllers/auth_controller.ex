defmodule AiAgentAdvisorWeb.AuthController do
  use AiAgentAdvisorWeb, :controller
  alias AiAgentAdvisor.Accounts

  plug Ueberauth

  def request(conn, _params) do
    render(conn, :index)
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.find_or_create_from_oauth(auth) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Logged in successfully!")
        # This is how we log the user in
        |> put_session(:user_id, user.id)
        |> redirect(to: "/")

      {:error, changeset} ->
        IO.inspect(changeset, label: "CHANGESET ERROR")

        conn
        |> put_flash(:error, "There was an error logging you in.")
        |> redirect(to: "/")
    end
  end

  @doc """
  Logs the user out.
  """
  def logout(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> configure_session(drop: true) 
    |> redirect(to: "/")
  end
end