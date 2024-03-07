defmodule PaymentServer.Users.User do
  use Ecto.Schema
  import Ecto.Changeset
  # import Ecto.Query

  schema "users" do
    field :name, :string
    field :email, :string

    has_many :wallets, PaymentServer.Wallets.Wallet
  end


  @required_parameters [:name]
  @available_parameters [:email | @required_parameters]
  def changeset(%__MODULE__{} = struct, params) do
    struct 
      |> cast(params, @available_parameters)
      |> validate_required(@required_parameters)
      |> validate_length(:name, min: 1, max: 30)
      |> cast_assoc(:wallets)
  end
end