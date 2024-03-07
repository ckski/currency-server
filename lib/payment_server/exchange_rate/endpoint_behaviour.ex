defmodule PaymentServer.ExchangeRate.EndpointBehaviour do
  @callback fetch_rate(String.t, String.t) :: {:ok, map()} | {:error, String.t}
end