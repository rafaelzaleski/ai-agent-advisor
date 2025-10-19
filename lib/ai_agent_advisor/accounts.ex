defmodule AiAgentAdvisor.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias AiAgentAdvisor.Repo

  alias AiAgentAdvisor.Accounts.User

  @doc """
  Gets a single user by their ID.
  """
  def get_user(id) when is_binary(id) do
    Repo.get(User, id)
  end

  @doc """
  Gets a single user by a set of params.
  """
  def get_user_by(params) do
    Repo.get_by(User, params)
  end

  @doc """
  Finds a user by provider and provider_id, or creates one if they don't exist.
  """
  def find_or_create_from_oauth(auth) do
     case get_user(auth.uid) do
      nil ->
        # User doesn't exist, create a new one
        %User{}
        |> User.google_login_changeset(auth)
        |> Repo.insert()

      user ->
        # User exists, update their tokens
        user
        |> User.google_login_changeset(auth)
        |> Repo.update()
    end
  end

  @doc """
  Updates an existing user with HubSpot credentials.
  """
  def link_hubspot_account(user, credentials) do
    expires_at =
      if credentials.expires_at do
        credentials.expires_at
        |> DateTime.from_unix!()
        |> DateTime.to_naive()
      else
        nil
      end

    user
    |> User.link_hubspot_changeset(%{
      hubspot_access_token: credentials.token,
      hubspot_refresh_token: credentials.refresh_token,
      hubspot_token_expires_at: expires_at
    })
    |> Repo.update()
  end
end
