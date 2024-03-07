defmodule PaymentServerWeb.Schema.Subscriptions.WalletTest do
  use PaymentServerWeb.SubscriptionCase
  use PaymentServer.DataCase, async: true

  alias PaymentServer.Wallets
  alias PaymentServer.Users
  alias PaymentServer.ExchangeRate

  @total_worth_changed_sub_doc  """
    subscription TotalWorthChanged($userId: ID!) {
      totalWorthChanged(userId: $userId) {
        amount
        currency
      }
    }
  """

  @send_money_doc """
    mutation SendMoney($fromUserId: ID!, $toUserId: ID!, $fromCurrency: String!, $toCurrency: String!, $amount: String!) {
      sendMoney(fromUserId: $fromUserId, toUserId: $toUserId, fromCurrency: $fromCurrency, toCurrency: $toCurrency, amount: $amount) {
        receiveAmount
        receiveCurrency
        sendAmount
        sendCurrency
      }
    }
  """

  describe "@total_worth_changed_sub" do
    setup do
      {:ok, user_1} = Users.create_user(%{name: "jack"})
      {:ok, user_2} = Users.create_user(%{name: "jill"})

      {:ok, wallet_1} = Wallets.create_wallet(%{user_id: user_1.id, currency: "CAD"})
      {:ok, _} = Wallets.create_wallet(%{user_id: user_2.id, currency: "USD"})
      
      wallet_1
      |> Wallets.Wallet.changeset(%{amount: "100.99"})
      |> Repo.update!

      ExchangeRate.set_initial_rate("CAD", "USD", "1.51")
      ExchangeRate.set_initial_rate("USD", "CAD", "0.98")

      %{user_id_1: user_1.id, user_id_2: user_2.id}
    end

    @tag runnable: true
    test "sends a change when @send_money mutation is triggered", %{
      socket: socket,
      user_id_1: first_user_id,
      user_id_2: second_user_id
    } do

      # Create subscription for first user.
      ref = push_doc(socket, @total_worth_changed_sub_doc, variables: %{
        userId: first_user_id
      })
      assert_reply ref, :ok, %{subscriptionId: subscription_id_1}
      
      # Create subscription for second user.
      ref = push_doc(socket, @total_worth_changed_sub_doc, variables: %{
        userId: second_user_id
      })
      assert_reply ref, :ok, %{subscriptionId: subscription_id_2}

      ref = push_doc socket, @send_money_doc, variables: %{
        fromUserId: first_user_id,
        toUserId: second_user_id,
        fromCurrency: "CAD",
        toCurrency: "USD",
        amount: "4.19"
      } 
      assert_reply ref, :ok, reply
      assert %{
        data: %{"sendMoney" => %{
          "receiveAmount" => "6.3269",
          "receiveCurrency" => "USD",
          "sendAmount" => "4.19",
          "sendCurrency" => "CAD"
        }}
      } = reply

      # Assert total worth for first user decreases.
      assert_push "subscription:data", data
      assert %{
        subscriptionId: ^subscription_id_1,
        result: %{
          data: %{
            "totalWorthChanged" => %{
              "amount" => "-4.19",
              "currency" => "CAD"
            }
          }
        }
      } = data

      # Assert toal worth for second user increases.
      assert_push "subscription:data", data
      assert %{
        subscriptionId: ^subscription_id_2,
        result: %{
          data: %{
            "totalWorthChanged" => %{
              "amount" => "6.3269",
              "currency" => "USD"
            }
          }
        }
      } = data
    end
  end
end