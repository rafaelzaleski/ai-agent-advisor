defmodule AiAgentAdvisorWeb.AuthController do
  use AiAgentAdvisorWeb, :controller
  plug Ueberauth

  alias AiAgentAdvisor.Accounts
  alias AiAgentAdvisor.Ingestion.DataSyncWorker

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case auth.provider do
      :google -> handle_google_login(conn, auth)
      :hubspot -> handle_hubspot_connect(conn, auth)
    end
  end

  def callback(%{assigns: %{ueberauth_failure: failed}} = conn, _params) do
    message =
      case failed.errors do
        [%Ueberauth.Failure.Error{message: msg} | _] -> msg
        _ -> "An unknown authentication error occurred."
      end

    conn
    |> put_flash(:error, "Authentication failed: #{message}")
    |> redirect(to: ~p"/")
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed due to an unexpected error.")
    |> redirect(to: ~p"/")
  end

  defp handle_google_login(conn, auth) do
    case Accounts.find_or_create_from_oauth(auth) do
      {:ok, user, :created} ->
        # This is a new user, trigger their first data sync
        {:ok, _job} = DataSyncWorker.new(%{user_id: user.id}) |> Oban.insert()

        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome! Your accounts are now syncing.")
        |> redirect(to: ~p"/chat")

      {:ok, user, :updated} ->
        # Existing user logged in
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: ~p"/chat")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Error signing in with Google.")
        |> redirect(to: ~p"/")
    end
  end

  defp handle_hubspot_connect(conn, auth) do
    case conn.assigns.current_user do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to connect your HubSpot account.")
        |> redirect(to: ~p"/")
        |> halt()

      user ->
        case Accounts.link_hubspot_account(user, auth.credentials) do
          {:ok, updated_user} ->
            # HubSpot was successfully linked, trigger a data sync
            {:ok, _job} = DataSyncWorker.new(%{user_id: updated_user.id}) |> Oban.insert()

            conn
            |> put_flash(:info, "HubSpot account connected and your data is now syncing.")
            |> redirect(to: ~p"/settings")

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Error connecting HubSpot account.")
            |> redirect(to: ~p"/settings")
        end
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "You have been logged out.")
    |> redirect(to: ~p"/")
  end
end
