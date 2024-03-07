defmodule PaymentServerWeb.Schema.Subscriptions.Wallet do
  use Absinthe.Schema.Notation

  object :wallet_subscriptions do
    field :total_worth_changed, :total_worth_change do
      arg :user_id, non_null(:id)

      config fn args, _ ->
        {:ok, topic: args.user_id}
      end
    end
  end
end