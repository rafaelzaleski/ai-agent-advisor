defmodule AiAgentAdvisorWeb.AuthController do
  use AiAgentAdvisorWeb, :controller

  plug Ueberauth

  # The route /auth/:provider (e.g., /auth/google) will call this action.
  # Its job is to simply start the Ueberauth flow.
  def request(conn, _params) do
    render(conn, :index)
  end

  # The callback route /auth/google/callback will end up here.
  # The user's data from Google is in conn.assigns.ueberauth_auth
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    IO.inspect(auth, label: "AUTH_CALLBACK_DATA")

    conn
    |> put_flash(:info, "Logged in successfully!")
    |> redirect(to: "/")
  end
end