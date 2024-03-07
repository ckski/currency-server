defmodule PaymentServerWeb.Resolvers.Wallet do
  alias PaymentServer.Wallets

  def find(args, _) do
    args = update_in(args.user_id, &String.to_integer/1)
    Wallets.find_wallet(args)
  end

  def create(args, _) do
    args = update_in(args.user_id, &String.to_integer/1)
    Wallets.create_wallet(args)
  end

  def send_money(args, _) do
    args = update_in(args.from_user_id, &String.to_integer/1)
    args = update_in(args.to_user_id, &String.to_integer/1)
    args = update_in(args.amount, fn amount_string ->
      {:ok, value} = Decimal.cast(amount_string)
      value
    end)
    Wallets.send_money(args)
  end

  def total_worth(args, _) do
    args = update_in(args.user_id, &String.to_integer/1)
    with {:ok, value} <- Wallets.total_worth(args) do
      {:ok, Decimal.to_string(value)}
    end
  end
end