defmodule PaymentServer.Repo.Migrations.AddUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :text
      add :email, :text
    end
  end
end
