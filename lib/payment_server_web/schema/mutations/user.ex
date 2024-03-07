defmodule PaymentServerWeb.Schema.Mutations.User do
  use Absinthe.Schema.Notation

  alias PaymentServerWeb.Resolvers.User

  object :user_mutations do
    field :create_user, :user do
      # arg :id, non_null(:id)
      arg :name, :string
      arg :email, :string

      resolve &User.create/2
    end
  end
end