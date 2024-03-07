defmodule PaymentServerWeb.Schema.Queries.Wallet do
  use Absinthe.Schema.Notation

  alias PaymentServerWeb.Resolvers.Wallet

  object :wallet_queries do
    field :user_wallets, list_of(:wallet) do
      arg :user_id, non_null(:id)
      arg :currency, :string

      resolve &Wallet.find/2
    end

    field :total_worth, :string do
      arg :user_id, non_null(:id)
      arg :currency, non_null(:string)

      resolve &Wallet.total_worth/2
    end
  end
end