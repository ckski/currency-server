defmodule PaymentServer.ExchangeRate do
  alias PaymentServer.ExchangeRate.Cache
  alias PaymentServer.ExchangeRate.EndpointImpl

  require Decimal
  import Decimal, only: [is_decimal: 1]

  @endpoint Application.compile_env(:payment_server, :exchange_rate_endpoint, EndpointImpl)

  def set_initial_rate(from_currency, to_currency, rate, cache \\ nil) do
    cond do
      is_binary(rate) ->
        Cache.put(cache, {from_currency, to_currency}, Decimal.new(rate))
      is_decimal(rate) ->
        Cache.put(cache, {from_currency, to_currency}, rate)
    end
  end

  def publish_new_rate(from, to, rate) when is_binary(rate), do: publish_new_rate(from, to, Decimal.new(rate))
  def publish_new_rate(from_currency, to_currency, rate) when is_decimal(rate) do
    pubsub = PaymentServerWeb.Endpoint
    data = %{from_currency: from_currency, to_currency: to_currency, rate: rate}
    topics = [
      exchange_rate_updated: "#{from_currency},*",
      exchange_rate_updated: "*,*",
      exchange_rate_updated: "*,#{to_currency}",
      exchange_rate_updated: "#{from_currency},#{to_currency}"
    ]

    Absinthe.Subscription.publish(pubsub, data, topics)
  end

  def get_latest_rate(from_currency, to_currency, cache \\ nil) do
    case Cache.get(cache, {from_currency, to_currency}) do
      nil -> throw :key_missing_in_cache
      value -> value
    end
  end

  def fetch_and_update_rate(from_currency, to_currency, cache) do
    with {:ok, %{rate: rate}} <- @endpoint.fetch_rate(from_currency, to_currency) do
      Cache.put(cache, {from_currency, to_currency}, rate)
      {:ok, rate}
    end
  end
end