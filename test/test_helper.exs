PaymentServer.ExchangeRate.set_initial_rate("CAD", "USD", "1.51")
PaymentServer.ExchangeRate.set_initial_rate("USD", "CAD", "0.98")

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(PaymentServer.Repo, :manual)