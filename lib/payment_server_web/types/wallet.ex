defmodule PaymentServerWeb.Types.Wallet do
  use Absinthe.Schema.Notation

  object :wallet do
    field :id, :id
    field :currency, :string
    field :amount, :string
  end

  object :wallet_transfer do
    field :send_amount, :string
    field :send_currency, :string

    field :receive_amount, :string
    field :receive_currency, :string
  end

  object :total_worth_change do
    field :amount, :string
    field :currency, :string
  end
end