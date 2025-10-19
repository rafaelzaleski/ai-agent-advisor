defmodule AiAgentAdvisor.Accounts.EncryptedBinary do
  use Cloak.Ecto.Binary, vault: AiAgentAdvisor.Vault
end
