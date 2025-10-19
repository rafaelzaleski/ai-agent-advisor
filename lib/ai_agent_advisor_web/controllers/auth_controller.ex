defmodule AiAgentAdvisorWeb.AuthController do
  use AiAgentAdvisorWeb, :controller
  plug Ueberauth

  alias AiAgentAdvisor.Accounts

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
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> redirect(to: ~p"/")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Could not authenticate with Google.")
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
          {:ok, _updated_user} ->
            conn
            |> put_flash(:info, "Successfully connected your HubSpot account!")
            |> redirect(to: ~p"/")

          {:error, changeset} ->
            # 🐛 DEBUG STEP 1: Inspect the full changeset
            IO.inspect(changeset, label: "HubSpot Link Error Changeset")

            # 🐛 DEBUG STEP 2: Inspect specific errors (if you want simpler output)
            IO.inspect(
              Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
                # This formats the error tuple into a human-readable string
                Enum.reduce(opts, msg, fn {key, value}, acc ->
                  String.replace(acc, "%{#{key}}", inspect(value))
                end)
              end),
              label: "HubSpot Changeset Errors"
            )
            conn
            |> put_flash(:error, "Could not connect your HubSpot account.")
            |> redirect(to: ~p"/")
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
