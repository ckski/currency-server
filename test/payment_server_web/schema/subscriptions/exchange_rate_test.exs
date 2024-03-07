defmodule PaymentServerWeb.Schema.Subscriptions.ExchangeRateTest do
  use PaymentServerWeb.SubscriptionCase

  alias PaymentServer.Users
  alias PaymentServer.Wallets
  alias PaymentServer.ExchangeRate

  @exchange_rate_updated_doc """
    subscription ExchangeRateUpdated($fromCurrency: String, $toCurrency: String) {
      exchangeRateUpdated(fromCurrency: $fromCurrency, toCurrency: $toCurrency) {
        fromCurrency
        toCurrency
        rate
      }
    }
  """

  describe "@exchange_rate_updated" do
    @tag runnable: true
    test "sends an exchange rate when subscribed using fromCurrency and toCurrency", %{
      socket: socket
    } do
      ref = push_doc(socket, @exchange_rate_updated_doc, variables: %{
        "fromCurrency" => "CAD",
        "toCurrency" => "USD"
      })

      assert_reply ref, :ok, %{subscriptionId: subscription_id}

      ExchangeRate.publish_new_rate("CAD", "USD", Decimal.new("1.01"))

      assert_push "subscription:data", data
      assert %{
        subscriptionId: ^subscription_id,
        result: %{
          data: %{
            "exchangeRateUpdated" => %{"fromCurrency" => "CAD", "rate" => "1.01", "toCurrency" => "USD"}
          }
        }
      } = data

      ExchangeRate.publish_new_rate("USD", "CAD", Decimal.new("0.98"))
      ExchangeRate.publish_new_rate("CAD", "USD", Decimal.new("0.93"))

      assert_push "subscription:data", data
      assert %{
        subscriptionId: ^subscription_id,
        result: %{
          data: %{
            "exchangeRateUpdated" => %{"fromCurrency" => "CAD", "rate" => "0.93", "toCurrency" => "USD"}
          }
        }
      } = data
    end

    @tag runnable: true
    test "sends an exchange rate when subscribed using fromCurrency only", %{
      socket: socket
    } do
      ref = push_doc(socket, @exchange_rate_updated_doc, variables: %{
        "fromCurrency" => "CAD"
      })

      assert_reply ref, :ok, %{subscriptionId: subscription_id}

      ExchangeRate.publish_new_rate("CAD", "USD", Decimal.new("1.01"))

      assert_push "subscription:data", data
      assert %{
        subscriptionId: ^subscription_id,
        result: %{
          data: %{
            "exchangeRateUpdated" => %{"fromCurrency" => "CAD", "rate" => "1.01", "toCurrency" => "USD"}
          }
        }
      } = data

      ExchangeRate.publish_new_rate("USD", "CAD", Decimal.new("0.98"))
      ExchangeRate.publish_new_rate("CAD", "USD", Decimal.new("0.93"))

      assert_push "subscription:data", data
      assert %{
        subscriptionId: ^subscription_id,
        result: %{
          data: %{
            "exchangeRateUpdated" => %{"fromCurrency" => "CAD", "rate" => "0.93", "toCurrency" => "USD"}
          }
        }
      } = data
    end

    @tag runnable: true
    test "sends an exchange rate when subscribed using toCurrency only", %{
      socket: socket
    } do
      ref = push_doc(socket, @exchange_rate_updated_doc, variables: %{
        "toCurrency" => "USD"
      })

      assert_reply ref, :ok, %{subscriptionId: subscription_id}

      ExchangeRate.publish_new_rate("CAD", "USD", Decimal.new("1.01"))

      assert_push "subscription:data", data
      assert %{
        subscriptionId: ^subscription_id,
        result: %{
          data: %{
            "exchangeRateUpdated" => %{"fromCurrency" => "CAD", "rate" => "1.01", "toCurrency" => "USD"}
          }
        }
      } = data

      ExchangeRate.publish_new_rate("USD", "CAD", Decimal.new("0.98"))
      ExchangeRate.publish_new_rate("AUD", "USD", Decimal.new("0.95"))

      assert_push "subscription:data", data
      assert %{
        subscriptionId: ^subscription_id,
        result: %{
          data: %{
            "exchangeRateUpdated" => %{"fromCurrency" => "AUD", "rate" => "0.95", "toCurrency" => "USD"}
          }
        }
      } = data
    end

    @tag runnable: true
    test "sends an exchange rate when subscribed to all", %{
      socket: socket
    } do
      ref = push_doc(socket, @exchange_rate_updated_doc, variables: %{})

      assert_reply ref, :ok, %{subscriptionId: subscription_id}

      ExchangeRate.publish_new_rate("CAD", "USD", Decimal.new("1.01"))

      assert_push "subscription:data", data
      assert %{
        subscriptionId: ^subscription_id,
        result: %{
          data: %{
            "exchangeRateUpdated" => %{"fromCurrency" => "CAD", "rate" => "1.01", "toCurrency" => "USD"}
          }
        }
      } = data

      ExchangeRate.publish_new_rate("USD", "CAD", Decimal.new("0.98"))

      assert_push "subscription:data", data
      assert %{
        subscriptionId: ^subscription_id,
        result: %{
          data: %{
            "exchangeRateUpdated" => %{"fromCurrency" => "USD", "rate" => "0.98", "toCurrency" => "CAD"}
          }
        }
      } = data
    end
  end
end