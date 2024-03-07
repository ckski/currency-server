# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PaymentServer.Repo.insert!(%PaymentServer.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias PaymentServer.Users.User
alias PaymentServer.Wallets.Wallet

PaymentServer.Repo.insert!(%User{
  name: "Chris",
  wallets: [
    %Wallet{
      currency: "CAD",
      amount: 100
    }
  ]
})