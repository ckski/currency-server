defmodule PaymentServer.Repo.Migrations.AddUniqueConstraintForWalletCurrency do
  use Ecto.Migration

  def change do
    create unique_index(:wallets, [:user_id, :currency])
  end
end
