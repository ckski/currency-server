defmodule PaymentServerWeb.Schema.Mutations.UserTest do
  use PaymentServer.DataCase, async: true

  alias PaymentServerWeb.Schema

  @create_user_doc """
    mutation CreateUser($name: String!, $email: String) {
      createUser(name: $name, email: $email) {
        id
        name
        email
      }
    }
  """

  @tag runnable: true
  describe "@create_user" do
    test "creates user with name and email" do
      assert {:ok, %{data: data}} = Absinthe.run(@create_user_doc, Schema,
        variables: %{
          "name" => "bob",
          "email" => "bob@example.com"
        }
      )

      assert %{
        "id" => _,
        "name" =>  "bob",
        "email" => "bob@example.com",
      } = data["createUser"]
    end
  end
end