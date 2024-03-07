defmodule PaymentServerWeb.Schema.Mutations.WalletTest do
  use PaymentServer.DataCase, async: true

  alias PaymentServerWeb.Schema
  alias PaymentServer.Users
  alias PaymentServer.Wallets
  alias PaymentServer.Repo
  alias PaymentServer.ExchangeRate


  @invalid_user_id 0
  @invalid_currency "INVALID"

  @create_wallet_doc """
    mutation CreateWallet($userId: ID!, $currency: String!) {
      createWallet(userId: $userId, currency: $currency) {
        id
        amount
        currency
      }
    }
  """

  describe "@create_wallet" do
    setup do
      {:ok,  user} = Users.create_user(%{name: "bob"})
      %{user_id: user.id}
    end

    @tag runnable: true
    test "creates wallet by user id and currency", %{user_id: user_id} do
      assert {:ok, %{data: data}} = Absinthe.run(@create_wallet_doc, Schema,
        variables: %{
          "userId" => user_id,
          "currency" => "CAD"
        }
      )

      assert %{
        "id" => _,
        "amount" =>  "0.00",
        "currency" => "CAD"
      } = data["createWallet"]
    end
    
    @tag runnable: true
    test "does not create wallet when user id is invalid" do
      assert {:ok, %{errors: errors}} = Absinthe.run(@create_wallet_doc, Schema,
        variables: %{
          "userId" => @invalid_user_id,
          "currency" => "CAD"
        }
      )

      assert [
        %{locations: _, message: "Invalid user id", path: ["createWallet"]}
      ] = errors
    end

    @tag runnable: true
    test "does not create wallet when currency is invalid", %{user_id: user_id} do
      assert {:ok, %{errors: errors}} = Absinthe.run(@create_wallet_doc, Schema,
        variables: %{
          "userId" => user_id,
          "currency" => @invalid_currency
        }
      )

      assert [
        %{locations: _, message: "currency: is invalid", path: ["createWallet"]}
      ] = errors
    end

    @tag runnable: true
    test "does not create wallet when wallet with same currency exists", %{user_id: user_id} do
      {:ok, _} = Wallets.create_wallet(%{user_id: user_id, currency: "CAD"})

      assert {:ok, %{errors: errors}} = Absinthe.run(@create_wallet_doc, Schema,
        variables: %{
          "userId" => user_id,
          "currency" => "CAD"
        }
      )

      assert [
        %{message: "currency: already exists", path: ["createWallet"]}
      ] = errors
    end    
  end


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

  describe "@send_money" do
    setup do
      {:ok, user_1} = Users.create_user(%{name: "jack"})
      {:ok, user_2} = Users.create_user(%{name: "jill"})

      %{user_id_1: user_1.id, user_id_2: user_2.id}
    end

    @tag runnable: true
    test "sends money with correct conversion", %{user_id_1: first_user_id, user_id_2: second_user_id} do
      {:ok, wallet_1} = Wallets.create_wallet(%{user_id: first_user_id, currency: "CAD"})      
      
      wallet_1
      |> Wallets.Wallet.changeset(%{amount: "100.99"})
      |> Repo.update!

      {:ok, wallet_2} = Wallets.create_wallet(%{user_id: second_user_id, currency: "USD"})

      assert {:ok, %{data: data}} = Absinthe.run(@send_money_doc, Schema,
        variables: %{
          "fromUserId" => first_user_id,
          "toUserId" => second_user_id,
          "fromCurrency" => "CAD",
          "toCurrency" => "USD",
          "amount" => "10.01"
        }
      )

      assert %{
        "receiveAmount" => "15.1151",
        "receiveCurrency" => "USD",
        "sendAmount" => "10.01",
        "sendCurrency" => "CAD"
      } === data["sendMoney"]

      wallet_1_after = Repo.reload(wallet_1)
      wallet_2_after = Repo.reload(wallet_2)

      assert Decimal.new("90.98") === wallet_1_after.amount
      assert Decimal.new("15.1151") === wallet_2_after.amount
    end

    @tag runnable: true
    test "sends money when currencies are the same", %{user_id_1: first_user_id, user_id_2: second_user_id} do
      {:ok, wallet_1} = Wallets.create_wallet(%{user_id: first_user_id, currency: "CAD"})
      
      wallet_1
      |> Wallets.Wallet.changeset(%{amount: "100.99"})
      |> Repo.update!

      {:ok, wallet_2} = Wallets.create_wallet(%{user_id: second_user_id, currency: "CAD"})

      assert {:ok, %{data: data}} = Absinthe.run(@send_money_doc, Schema,
        variables: %{
          "fromUserId" => first_user_id,
          "toUserId" => second_user_id,
          "fromCurrency" => "CAD",
          "toCurrency" => "CAD",
          "amount" => "10.01"
        }
      )

      assert %{
        "receiveAmount" => "10.01",
        "receiveCurrency" => "CAD",
        "sendAmount" => "10.01",
        "sendCurrency" => "CAD"
      } === data["sendMoney"]

      wallet_1_after = Repo.reload(wallet_1)
      wallet_2_after = Repo.reload(wallet_2)

      assert Decimal.new("90.98") === wallet_1_after.amount
      assert Decimal.new("10.01") === wallet_2_after.amount
    end

    @tag runnable: true
    test "sends money when user ids are same but currencies are different", %{user_id_1: first_user_id, user_id_2: second_user_id} do
      {:ok, wallet_1} = Wallets.create_wallet(%{user_id: first_user_id, currency: "CAD"})
      {:ok, wallet_2} = Wallets.create_wallet(%{user_id: first_user_id, currency: "USD"})
      
      wallet_1
      |> Wallets.Wallet.changeset(%{amount: "100.99"})
      |> Repo.update!

      wallet_2
      |> Wallets.Wallet.changeset(%{amount: "0.01"})
      |> Repo.update!

      assert {:ok, %{data: data}} = Absinthe.run(@send_money_doc, Schema,
        variables: %{
          "fromUserId" => first_user_id,
          "toUserId" => first_user_id,
          "fromCurrency" => "USD",
          "toCurrency" => "CAD",
          "amount" => "0.01"
        }
      )

      assert %{
        "sendAmount" => "0.01",
        "sendCurrency" => "USD",
        "receiveAmount" => "0.0098",
        "receiveCurrency" => "CAD"
      } === data["sendMoney"]

      wallet_1_after = Repo.reload(wallet_1)
      wallet_2_after = Repo.reload(wallet_2)

      assert Decimal.new("100.9998") === wallet_1_after.amount
      assert Decimal.new("0.00") === wallet_2_after.amount
    end

    @tag runnable: true
    test "does not send money when wallets are the same", %{user_id_1: first_user_id, user_id_2: second_user_id} do
      {:ok, wallet} = Wallets.create_wallet(%{user_id: first_user_id, currency: "CAD"})
      
      wallet
      |> Wallets.Wallet.changeset(%{amount: "100.99"})
      |> Repo.update!

      assert {:ok, %{errors: errors}} = Absinthe.run(@send_money_doc, Schema,
        variables: %{
          "fromUserId" => first_user_id,
          "toUserId" => first_user_id,
          "fromCurrency" => "CAD",
          "toCurrency" => "CAD",
          "amount" => "10.01"
        }
      )

      assert [
        %{locations: _, message: "cannot send money to the same wallet", path: ["sendMoney"]}
      ] = errors
    end
    
    @tag runnable: true
    test "does not send money when not enough money in wallet", %{user_id_1: first_user_id, user_id_2: second_user_id} do
      {:ok, wallet_1} = Wallets.create_wallet(%{user_id: first_user_id, currency: "CAD"})
      
      wallet_1
      |> Wallets.Wallet.changeset(%{amount: "100.99"})
      |> Repo.update!

      {:ok, _} = Wallets.create_wallet(%{user_id: second_user_id, currency: "USD"})

      assert {:ok, %{errors: errors}} = Absinthe.run(@send_money_doc, Schema,
        variables: %{
          "fromUserId" => first_user_id,
          "toUserId" => second_user_id,
          "fromCurrency" => "CAD",
          "toCurrency" => "USD",
          "amount" => "101.00"
        }
      )

      assert [
        %{locations: _, message: "insufficient funds", path: ["sendMoney"]}
      ] = errors
    end

    @tag runnable: true
    test "returns error when fromUserId is invalid", %{user_id_1: first_user_id} do
      assert {:ok, %{errors: errors}} = Absinthe.run(@send_money_doc, Schema,
        variables: %{
          "fromUserId" => @invalid_user_id,
          "toUserId" => first_user_id,
          "fromCurrency" => "CAD",
          "toCurrency" => "USD",
          "amount" => "101.00"
        }
      )

      assert [
        %{locations: _, message: "wallet not found", path: ["sendMoney"]}
      ] = errors
    end

    @tag runnable: true
    test "returns error when toUserId is invalid", %{user_id_1: first_user_id} do
      assert {:ok, %{errors: errors}} = Absinthe.run(@send_money_doc, Schema,
        variables: %{
          "fromUserId" => first_user_id,
          "toUserId" => @invalid_user_id,
          "fromCurrency" => "CAD",
          "toCurrency" => "USD",
          "amount" => "101.00"
        }
      )

      assert [
        %{locations: _, message: "wallet not found", path: ["sendMoney"]}
      ] = errors
    end

    @tag runnable: true
    test "returns error when fromCurrency is invalid", %{user_id_1: first_user_id, user_id_2: second_user_id} do
      assert {:ok, %{errors: errors}} = Absinthe.run(@send_money_doc, Schema,
        variables: %{
          "fromUserId" => first_user_id,
          "toUserId" => second_user_id,
          "fromCurrency" => @invalid_currency,
          "toCurrency" => "USD",
          "amount" => "101.00"
        }
      )

      assert [
        %{locations: _, message: "wallet not found", path: ["sendMoney"]}
      ] = errors
    end

    @tag runnable: true
    test "returns error when toCurrency is invalid", %{user_id_1: first_user_id, user_id_2: second_user_id} do
      assert {:ok, %{errors: errors}} = Absinthe.run(@send_money_doc, Schema,
        variables: %{
          "fromUserId" => first_user_id,
          "toUserId" => second_user_id,
          "fromCurrency" => "CAD",
          "toCurrency" => @invalid_currency,
          "amount" => "101.00"
        }
      )

      assert [
        %{locations: _, message: "wallet not found", path: ["sendMoney"]}
      ] = errors
    end
  end
end