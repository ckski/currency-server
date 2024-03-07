defmodule PaymentServerWeb.Schema.Queries.User do
  use Absinthe.Schema.Notation

  alias PaymentServerWeb.Resolvers.User

  object :user_queries do
    field :user, :user do
      arg :id, non_null(:id)

      resolve &User.find/2
    end
  end
end