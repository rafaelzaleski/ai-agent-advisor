defmodule AiAgentAdvisor.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias AiAgentAdvisor.Accounts.EncryptedBinary

  @primary_key {:id, :string, autogenerate: false}
  schema "users" do
    field :email, :string
    field :provider, :string
    field :google_access_token, EncryptedBinary
    field :google_refresh_token, EncryptedBinary
    field :google_token_expires_at, :naive_datetime
    field :hubspot_access_token, EncryptedBinary
    field :hubspot_refresh_token, EncryptedBinary
    field :hubspot_token_expires_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :provider, :provider_id])
    |> validate_required([:email, :provider, :provider_id])
    |> unique_constraint([:provider, :provider_id], name: :users_provider_provider_id_index)
  end

  def google_login_changeset(user, auth) do
    attrs = %{
      id: auth.uid,
      email: auth.info.email,
      provider: Atom.to_string(auth.provider),
      google_access_token: auth.credentials.token,
      google_refresh_token: auth.credentials.refresh_token,
      google_token_expires_at:
        (auth.credentials.expires_at &&
           DateTime.from_unix!(auth.credentials.expires_at) |> DateTime.to_naive())
    }

    user
    |> cast(attrs, [
      :id,
      :email,
      :provider,
      :google_access_token,
      :google_refresh_token,
      :google_token_expires_at
    ])
    |> validate_required([:id, :email, :provider])
  end

  @doc false
  def link_hubspot_changeset(user, attrs) do
    user
    |> cast(attrs, [:hubspot_access_token, :hubspot_refresh_token, :hubspot_token_expires_at])
    |> validate_required([:hubspot_access_token])
  end
end
