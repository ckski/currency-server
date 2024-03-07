defmodule PaymentServer.Repo.Migrations.AddWalletsTable do
  use Ecto.Migration

  def change do
    create table(:wallets) do
      add :currency, :text
      add :amount, :decimal
    end
  end
end
