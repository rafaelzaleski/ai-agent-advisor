defmodule AiAgentAdvisor.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias AiAgentAdvisor.Repo

  alias AiAgentAdvisor.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user by specific criteria.

  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user_by(email: "foo@bar.com")
      %User{}

      iex> get_user_by(email: "unknown@bar.com")
      nil

  """
  def get_user_by(clauses) when is_list(clauses) do
    Repo.get_by(User, clauses)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  # --- NOSSA FUNÇÃO DE LOGIN COMEÇA AQUI ---

  @doc """
  Finds a user by provider and provider_id, or creates one if they don't exist.
  """
  def find_or_create_from_oauth(auth) do
    # Usamos a função que o Phoenix gerou para nós
    user = get_user_by(
      provider: Atom.to_string(auth.provider),
      provider_id: auth.uid
    )

    # Se o usuário não existir (for nil), crie um novo.
    if user do
      {:ok, user}
    else
      # Usamos a outra função que o Phoenix gerou
      create_user(%{
        email: auth.info.email,
        name: auth.info.name,
        provider: Atom.to_string(auth.provider),
        provider_id: auth.uid
      })
    end
  end
end