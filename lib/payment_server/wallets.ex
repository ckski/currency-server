defmodule PaymentServer.Wallets do
  require Ecto.Query
  import Decimal, only: [is_decimal: 1]
  
  alias EctoShorts.Actions
  alias Ecto.Multi

  import PaymentServer.SubscriptionPublishing, only: [publish_total_worth_change: 2]
  
  alias PaymentServer.ExchangeRate
  alias PaymentServer.Repo
  alias PaymentServer.Users
  alias PaymentServer.Wallets.Wallet 

  @valid_currencies Enum.into(Application.compile_env(:payment_server, :supported_currencies), MapSet.new())

  def find_wallet(%{user_id: user_id} = params) when is_integer(user_id) do
    {:ok, Actions.all(Wallet, params)}
  end

  def get_wallet(params) do
    case Actions.all(Wallet, params) do
      [] -> {:error, "wallet not found"}
      [wallet] -> {:ok, wallet}
    end
  end

  def create_wallet(%{user_id: user_id, currency: currency} = params) when is_integer(user_id) do
    if Users.valid_user?(user_id) do
      Actions.create(Wallet, params)
    else
      {:error, "Invalid user id"}
    end
  end

  def total_worth(%{user_id: user_id, currency: currency}) when is_integer(user_id) do
    cond do
      not MapSet.member?(@valid_currencies, currency) ->
        {:error, "Invalid currency"}

      not Users.valid_user?(user_id) ->
        {:error, "Invalid user id"}

      true ->
        with {:ok, wallets} <- find_wallet(%{user_id: user_id}) do
          calculate_total_worth_of_wallets(wallets, currency) 
        end
    end
  end

  defp calculate_total_worth_of_wallets(wallets, into_currency) do
    total =
      wallets
      |> Enum.map(fn %Wallet{amount: amount, currency: wallet_currency} ->
        cond do
          Decimal.eq?(amount, 0) ->
            Decimal.new("0.00")
          
          wallet_currency === into_currency ->
            amount
          
          true ->
            Decimal.mult(amount, ExchangeRate.get_latest_rate(wallet_currency, into_currency))
        end
      end)
      |> Enum.reduce(Decimal.new("0.00"), &Decimal.add/2)

    {:ok, total}
  end

  def send_money(%{from_user_id: user_id, to_user_id: user_id, from_currency: currency, to_currency: currency}) do
    {:error, "cannot send money to the same wallet"}
  end
  def send_money(%{from_user_id: from_user_id, to_user_id: to_user_id, amount: amount} = params)
    when is_integer(from_user_id) and is_integer(to_user_id) and is_decimal(amount) do
    
    %{
      from_currency: from_currency, 
      to_currency: to_currency
    } = params

    with {:ok, from_wallet} <- get_wallet(%{user_id: from_user_id, currency: from_currency}),
         {:ok, to_wallet} <- get_wallet(%{user_id: to_user_id, currency: to_currency}),
         :ok <- check_sufficient_funds(from_wallet, amount),
         {:ok, ret} <- convert_money_transfer(from_wallet, to_wallet, amount) do
      
      %{
        send_currency: send_currency,
        send_amount: send_amount,
        receive_currency: receive_currency,
        receive_amount: receive_amount
      } = ret

      case Repo.transaction(money_transfer_update(from_wallet, to_wallet, send_amount, receive_amount)) do
        {:ok, _} ->
          publish_total_worth_change(from_user_id, %{currency: from_currency, amount: Decimal.negate(send_amount)})
          publish_total_worth_change(to_user_id, %{currency: to_currency, amount: receive_amount})
          {:ok, ret}

        {:error, _failed_operation, _failed_value, _changes_so_far} ->
          {:error, "error occurred in transfer transaction"}
      end
    end
  end

  defp check_sufficient_funds(from_wallet, amount) do
    if from_wallet.amount < amount do
      {:error, "insufficient funds"}
    else
      :ok
    end
  end

  defp convert_money_transfer(from_wallet, to_wallet, amount) do
    from_currency = from_wallet.currency
    to_currency = to_wallet.currency

    ret = %{
      send_currency: from_currency,
      send_amount: amount,
    }

    if from_currency === to_currency do
      {:ok,
        Map.merge(ret, %{
          receive_currency: to_currency,
          receive_amount: amount
        })
      }

    else
      receive_amount = Decimal.mult(amount, ExchangeRate.get_latest_rate(from_currency, to_currency))
      {:ok, 
        Map.merge(ret, %{
          receive_currency: to_currency,
          receive_amount: receive_amount
        })
      }
    end
  end

  defp money_transfer_update(from_wallet, to_wallet, send_amount, receive_amount) do
    from_changeset = Wallet.changeset(from_wallet, %{
      amount: Decimal.sub(from_wallet.amount, send_amount)
    })
    to_changeset = Wallet.changeset(to_wallet, %{
      amount: Decimal.add(to_wallet.amount, receive_amount)
    })

    Multi.new()
    |> Multi.update(:from_wallet, from_changeset)
    |> Multi.update(:to_wallet, to_changeset)
  end
end