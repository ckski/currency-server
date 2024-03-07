defmodule PaymentServerWeb.Schema.Mutations.Wallet do
  use Absinthe.Schema.Notation

  alias PaymentServerWeb.Resolvers.Wallet

  object :wallet_mutations do
    field :create_wallet, :wallet do
      arg :user_id, non_null(:id)
      arg :currency, non_null(:string)

      resolve &Wallet.create/2
    end

    field :send_money, :wallet_transfer do
      arg :from_user_id, non_null(:id)
      arg :to_user_id, non_null(:id)
      arg :from_currency, non_null(:string)
      arg :to_currency, non_null(:string)
      arg :amount, non_null(:string)

      resolve &Wallet.send_money/2
    end
  end
end