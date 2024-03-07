defmodule PaymentServerWeb.Schema.Subscriptions.ExchangeRate do
  use Absinthe.Schema.Notation

  require Logger

  @valid_currencies Enum.into(Application.compile_env(:payment_server, :supported_currencies), MapSet.new())

  object :exchange_rate_subscriptions do
    field :exchange_rate_updated, :exchange_rate do
      arg :from_currency, :string
      arg :to_currency, :string

      config fn args, _ ->
        with {:ok, from_topic_fragment} <- validate_arg(args[:from_currency]),
             {:ok, to_topic_fragment} <- validate_arg(args[:to_currency]) do
          {:ok, topic: "#{from_topic_fragment},#{to_topic_fragment}"}
        end
      end
    end
  end

  defp validate_arg(nil), do: {:ok, "*"}
  defp validate_arg(currency) when is_binary(currency) do
    if MapSet.member?(@valid_currencies, currency) do
      {:ok, currency}
    else
      {:error, "Invalid currency"}
    end
  end
end