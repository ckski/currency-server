defmodule PaymentServerWeb.Schema.Queries.WalletTest do
  use PaymentServer.DataCase, async: true

  alias PaymentServerWeb.Schema
  alias PaymentServer.Users
  alias PaymentServer.Wallets
  alias PaymentServer.ExchangeRate

  @total_worth_doc """
    query TotalWorth($userId: ID!, $currency: String!) {
      totalWorth(userId: $userId, currency: $currency)
    }
  """

  describe "@total_worth" do
    @invalid_user_id 0
    @invalid_currency "INVALID"

    setup do
      {:ok, user} = Users.create_user(%{name: "jill"})

      {:ok, wallet_1} = Wallets.create_wallet(%{user_id: user.id, currency: "CAD"})      
      {:ok, wallet_2} = Wallets.create_wallet(%{user_id: user.id, currency: "USD"})      
      {:ok, _wallet_3} = Wallets.create_wallet(%{user_id: user.id, currency: "AUD"})

      wallet_1
      |> Wallets.Wallet.changeset(%{amount: "100.99"})
      |> Repo.update!
      wallet_2
      |> Wallets.Wallet.changeset(%{amount: "9.01"})
      |> Repo.update!

      # ExchangeRate.set_initial_rate("CAD", "USD", "1.51")
      # ExchangeRate.set_initial_rate("USD", "CAD", "0.98")

      %{user_id: user.id}
    end

    @tag runnable: true
    test "fetches total worth by user id and currency (USD)", %{user_id: user_id} do
      assert {:ok, %{data: data}} = Absinthe.run(@total_worth_doc,  Schema,
        variables: %{
          "userId" => user_id,
          "currency" => "USD"
        }
      )

      assert "161.5049" === data["totalWorth"]
    end

    @tag runnable: true
    test "fetches total worth by user id and currency (CAD)", %{user_id: user_id} do
      assert {:ok, %{data: data}} = Absinthe.run(@total_worth_doc,  Schema,
        variables: %{
          "userId" => user_id,
          "currency" => "CAD"
        }
      )

      assert "109.8198" === data["totalWorth"]
    end


    @tag runnable: true
    test "returns 0.00 when user has no wallets", %{user_id: user_id} do
      {:ok, user} = Users.create_user(%{name: "jack"})

      assert {:ok, %{data: data}} = Absinthe.run(@total_worth_doc,  Schema,
        variables: %{
          "userId" => user.id,
          "currency" => "CAD"
        }
      )

      assert "0.00" === data["totalWorth"]
    end

    @tag runnable: true
    test "returns error if user id is invalid" do
      assert {:ok, %{errors: errors}} = Absinthe.run(@total_worth_doc,  Schema,
        variables: %{
          "userId" => @invalid_user_id,
          "currency" => "CAD"
        }
      )

      assert [
        %{locations: _, message: "Invalid user id", path: ["totalWorth"]}
      ] = errors
    end

    @tag runnable: true
    test "returns error if currency is invalid" do
      assert {:ok,  user} = Users.create_user(%{name: "bob"})


      assert {:ok, %{errors: errors}} = Absinthe.run(@total_worth_doc,  Schema,
        variables: %{
          "userId" => user.id,
          "currency" => @invalid_currency
        }
      )

      assert [
        %{locations: _, message: "Invalid currency", path: ["totalWorth"]}
      ] = errors
    end
  end


  @user_wallets_doc """
    query UserWallets($userId: ID!, $currency: String) {
      userWallets(userId: $userId, currency: $currency) {
        id
        amount
        currency
      }
    }
  """

  describe "@user_wallets" do
    @invalid_user_id 0
    @invalid_currency "INVALID"

    setup do
      {:ok, user} = Users.create_user(%{name: "jill"})

      {:ok, wallet_1} = Wallets.create_wallet(%{user_id: user.id, currency: "CAD"})      
      {:ok, wallet_2} = Wallets.create_wallet(%{user_id: user.id, currency: "USD"})      
      {:ok, _wallet_3} = Wallets.create_wallet(%{user_id: user.id, currency: "AUD"})
            
      wallet_1
      |> Wallets.Wallet.changeset(%{amount: "100.99"})
      |> Repo.update!
      wallet_2
      |> Wallets.Wallet.changeset(%{amount: "9.01"})
      |> Repo.update!

      %{user_id: user.id}
    end

    @tag runnable: true
    test "fetches all wallets by user id", %{user_id: user_id} do
      assert {:ok, %{data: data}} = Absinthe.run(@user_wallets_doc,  Schema,
        variables: %{
          "userId" => user_id
        }
      )

      result = data["userWallets"] |> Enum.map(&Map.drop(&1, ["id"])) |> Enum.sort

      assert Enum.sort([
        %{"amount" => "100.99", "currency" => "CAD"},
        %{"amount" => "9.01", "currency" => "USD"},
        %{"amount" => "0.00", "currency" => "AUD"} 
      ]) === result
    end

    @tag runnable: true
    test "fetches wallet by user id and currency", %{user_id: user_id} do
      assert {:ok, %{data: data}} = Absinthe.run(@user_wallets_doc,  Schema,
        variables: %{
          "userId" => user_id,
          "currency" => "CAD"
        }
      )

      assert [
        %{"amount" => "100.99", "currency" => "CAD", "id" => _}
      ] = data["userWallets"]
    end

    @tag runnable: true
    test "returns [] when user has no wallets", %{user_id: user_id} do
      {:ok, user} = Users.create_user(%{name: "jack"})

      assert {:ok, %{data: data}} = Absinthe.run(@user_wallets_doc,  Schema,
        variables: %{
          "userId" => user.id,
          "currency" => "CAD"
        }
      )

      assert [] === data["userWallets"]
    end

    @tag runnable: true
    test "returns [] when user has no wallets and no currency argument is used", %{user_id: user_id} do
      {:ok, user} = Users.create_user(%{name: "jack"})

      assert {:ok, %{data: data}} = Absinthe.run(@user_wallets_doc,  Schema,
        variables: %{
          "userId" => user.id
        }
      )

      assert [] === data["userWallets"]
    end

    @tag runnable: true
    test "returns [] when user id is invalid", %{user_id: user_id} do
      assert {:ok, %{data: data}} = Absinthe.run(@user_wallets_doc,  Schema,
        variables: %{
          "userId" => @invalid_user_id,
          "currency" => "CAD"
        }
      )

      assert [] === data["userWallets"]
    end

    @tag runnable: true
    test "returns [] when user id is invalid and no currency argument is used", %{user_id: user_id} do
      assert {:ok, %{data: data}} = Absinthe.run(@user_wallets_doc,  Schema,
        variables: %{
          "userId" => @invalid_user_id
        }
      )

      assert [] === data["userWallets"]
    end

    @tag runnable: true
    test "returns [] when currency is invalid", %{user_id: user_id} do
      assert {:ok, %{data: data}} = Absinthe.run(@user_wallets_doc,  Schema,
        variables: %{
          "userId" => user_id,
          "currency" => @invalid_currency
        }
      )

      assert [] === data["userWallets"]
    end
  end

end