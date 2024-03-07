defmodule PaymentServer.Users do
  alias PaymentServer.Repo
  alias PaymentServer.Users.User
  alias EctoShorts.Actions

  def find_user(params) do
    Actions.find(User, params)
  end

  def create_user(params) do
    Actions.create(User, params)
  end

  def valid_user?(id) when is_integer(id) do
    Repo.get(User, id) !== nil
  end

end