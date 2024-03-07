defmodule PaymentServer.Support.ExchangeRate.TestEndpoint do
  @behaviour PaymentServer.ExchangeRate.EndpointBehaviour

  @impl true
  def fetch_rate("CAD", "USD") do
    {:ok, %{rate: "1.51"}}
  end
  def fetch_rate(_, _) do
    {:ok, %{rate: "0.98"}}
  end
end