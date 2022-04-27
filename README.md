# silhouette

An Elixir Graphql Client

### Potential API Design:

```elixir
defmodule PhoneNumber do
  defstruct number: ""
end

defmodule User do
  defstruct first_name: "", last_name: "", phone_numbers: [], messages: []

  def get(id) do
    phone_numbers_selection =
      SelectionSet.succeed(%PhoneNumber{})
      |> SelectionSet.with(:number)

    user_selection =
      SelectionSet.succeed(%User{})
      |> SelectionSet.with(:first_name)
      |> SelectionSet.with(:last_name)
      |> SelectionSet.with(:phone_numbers, list_of: phone_numbers_selection)

    Graphql.query(:user, user_selection)
    |> Graphql.variables(%{user_id: id})
  end

  def create(attrs) do
    user_selection =
      SelectionSet.succeed(%User{})
      |> SelectionSet.with(:first_name)
      |> SelectionSet.with(:last_name)
      |> SelectionSet.with(:messages, list_of: :string)

    Graphql.mutation(:createUser, user_selection)
    |> Graphql.variables(attrs)
  end
end

User.create(%User{first_name: "Thomas", last_name: "Brewer"})
|> Graphql.execute()
|> case do
  {:ok, user} -> IO.inspect(user)
  {:error, messages} -> IO.inspect(messages)
end

User.get(1)
|> Graphql.execute()
|> case do
  {:ok, user} -> IO.inspect(user)
  {:error, msg} -> IO.inspect(msg)
end
```
