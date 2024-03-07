defmodule PaymentServer.Repo.Migrations.AddWalletBelongsToUser do
  use Ecto.Migration

  def change do
    alter table(:wallets) do
      add :user_id, references(:users, on_delete: :delete_all)
    end
  end
end
