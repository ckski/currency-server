defmodule PaymentServerWeb.Schema.Queries.UserTest do
  use PaymentServer.DataCase, async: true

  alias PaymentServerWeb.Schema
  alias PaymentServer.Users

  @user_doc """
    query User($id: ID!) {
      user(id: $id) {
        id
        name
        email
      }
    }
  """
  
  @tag runnable: true
  describe "@user" do
    test "fetches user by id" do
      assert {:ok,  user} = Users.create_user(%{
        name: "bob",
        email: "bob@example.com"
      })

      assert {:ok, %{data: data}} = Absinthe.run(@user_doc,  Schema,
        variables: %{
          "id" => user.id
        }
      )

      assert data["user"]["id"] === to_string(user.id)
    end
  end
end