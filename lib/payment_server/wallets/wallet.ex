defmodule PaymentServer.Wallets.Wallet do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_currencies Enum.into(Application.compile_env(:payment_server, :supported_currencies), MapSet.new())

  schema "wallets" do
    field :currency, :string
    field :amount, :decimal

    belongs_to :user, PaymentServer.Users.User
  end

  @required_parameters [:currency, :amount]
  @available_parameters [:user_id | @required_parameters]
  def changeset(%__MODULE__{} = struct, params) do
    params = 
      params
      |> Map.put_new(:amount, "0.00")
      |> Map.replace_lazy(:currency, &String.upcase/1)

    struct
      |> cast(params, @available_parameters)
      |> validate_required(@required_parameters)
      |> validate_number(:amount, greater_than_or_equal_to: 0)
      |> validate_inclusion(:currency, @valid_currencies)
      |> unique_constraint([:user_id, :currency], error_key: :currency, message: "already exists")
  end
end