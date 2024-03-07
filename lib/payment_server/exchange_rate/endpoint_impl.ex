defmodule PaymentServer.ExchangeRate.EndpointImpl do
  alias PaymentServer.ExchangeRate

  @behaviour ExchangeRate.EndpointBehaviour
  
  @base_url Application.compile_env!(:payment_server, :exchange_rate_endpoint_url)
  @api_key "demo"

  @impl ExchangeRate.EndpointBehaviour
  def fetch_rate(from_currency, to_currency) do
    url = @base_url <> "query"
    headers = []
    params = %{
      "apiKey" => @api_key,
      "function" => "CURRENCY_EXCHANGE_RATE",
      "from_currency" => from_currency,
      "to_currency" => to_currency
    }

    case HTTPoison.get(url, headers, params: params) do
      {:ok, %HTTPoison.Response{body: body}} -> decode_rate_result(body)
      {:error, error} -> {:error, "endpoint error: #{inspect error}"}
    end
  end

  defp decode_rate_result(body) do
    json = Jason.decode!(body)
    data = json["Realtime Currency Exchange Rate"]

    {:ok, 
      %{
        rate: data["5. Exchange Rate"]
      }
    }
  end
end