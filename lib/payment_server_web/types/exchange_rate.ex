defmodule PaymentServerWeb.Types.ExchangeRate do
  use Absinthe.Schema.Notation

  object :exchange_rate do
    field :from_currency, :string
    field :to_currency, :string
    field :rate, :string
  end

end