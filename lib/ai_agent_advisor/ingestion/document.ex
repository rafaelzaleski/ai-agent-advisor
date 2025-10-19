defmodule AiAgentAdvisor.Ingestion.Document do
  use Ecto.Schema
  import Ecto.Changeset
  alias Pgvector.Ecto.Vector
  alias AiAgentAdvisor.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "documents" do
    field :content, :string
    field :embedding, Vector
    field :source, :string
    field :source_id, :string

    belongs_to :user, User, type: :string

    timestamps()
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [:user_id, :content, :embedding, :source, :source_id])
    |> validate_required([:user_id, :content, :embedding, :source])
  end
end
