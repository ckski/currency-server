defmodule PaymentServerWeb.Schema do
  use Absinthe.Schema

  alias PaymentServerWeb.Schema.Middleware
  
  import_types PaymentServerWeb.Types.User
  import_types PaymentServerWeb.Types.Wallet
  import_types PaymentServerWeb.Types.ExchangeRate
  
  import_types __MODULE__.Queries.User
  import_types __MODULE__.Queries.Wallet

  import_types __MODULE__.Mutations.User
  import_types __MODULE__.Mutations.Wallet

  import_types __MODULE__.Subscriptions.ExchangeRate
  import_types __MODULE__.Subscriptions.Wallet

  query do
    import_fields :user_queries
    import_fields :wallet_queries
  end

  mutation do
    import_fields :user_mutations
    import_fields :wallet_mutations
  end

  subscription do
    import_fields :wallet_subscriptions
    import_fields :exchange_rate_subscriptions
  end

  def context(ctx) do
    source = Dataloader.Ecto.new(PaymentServer.Repo)
    dataloader = Dataloader.add_source(Dataloader.new(), PaymentServer.Wallets, source)
    Map.put(ctx, :loader, dataloader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  def middleware(middleware, _field, %{identifier: :mutation}) do
    middleware ++ [Middleware.HandleChangesetErrors]
  end
  def middleware(middleware, _field, _object) do
    middleware
  end
end