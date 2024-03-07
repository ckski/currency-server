defmodule PaymentServerWeb.Resolvers.User do
  alias PaymentServer.Users

  def find(params, _) do
    Users.find_user(params)
  end

  def create(args, _) do
    Users.create_user(args)
  end
end