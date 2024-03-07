defmodule PaymentServerWeb.Types.User do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  object :user do
    field :id, :id
    field :name, :string
    field :email, :string

    field :wallets, :wallet, resolve: dataloader(PaymentServer.Wallets, :wallets)
  end
end