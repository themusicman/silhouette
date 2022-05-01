# Silhouette (Alpha)

An Elixir Graphql Client

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `silhouette` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:silhouette, "~> 0.1.0"}
  ]
end
```

## Goals

- Composable
- Possibly code generation based on Graphql introspection
- Support Subscriptions (hopefully)
- Support for changsets (maybe just Ecto changsets)

## Examples

See the `examples` directory for examples of how to use this package. Feel free to submit a pull request adding more of them. :)

## Potential API Design:

```elixir

defmodule Graphql.Scalar.Custom do
  @callback to(value :: any()) :: {:ok, binary()} | {:error, atom()}
  @callback from(value :: any()) :: {:ok, any()} | {:error, atom()}
end

defmodule Graphql.Scalar.Custom.DateTime do
  @behaviour Graphql.Scalar.Custom

  def to(value) do
    {:ok, DateTime.to_string(value)}
  end

  def from(value) do
    case DateTime.to_iso8601(value) do
      {:ok, datetime, _} -> {:ok, datetime}
      {:error, error} -> {:error, error}
    end
  end
end

defmodule PhoneNumber do
  defstruct number: ""
end

defmodule User do
  defstruct first_name: "", last_name: "", phone_numbers: [], created_at: nil

  defmodule UserInput do
    defstruct first_name: "", last_name: ""
  end

  # query User($id: ID!) {
  #    user(id: $id) {
  #        id
  #        firstName
  #        lastName
  #        createdAt
  #        phoneNumbers {
  #            number
  #        }
  #    }
  #  }
  def get(id) do
    phone_numbers_selection =
      SelectionSet.into(%PhoneNumber{})
      |> SelectionSet.with(:number, as: :string)

    user_selection =
      SelectionSet.into(%User{})
      |> SelectionSet.with(:first_name, as: :string)
      |> SelectionSet.with(:last_name, as: :string)
      |> SelectionSet.with(:created_at, as: :datetime)
      |> SelectionSet.with(:phone_numbers, list_of: phone_numbers_selection)

    Graphql.query(for: :user, one_of: user_selection)
    |> Graphql.arguments(%{id: "ID!"})
    |> Graphql.variables(%{id: id})
    |> Graphql.headers(%{"Authorization" => "Bearer tokenhere")
    |> Graphql.url("https://example.com/graphql")
  end

  # mutation CreateUser($user: UserInput!) {
  #    createUser(user: $user) {
  #      result {
  #        id
  #        firstName
  #        lastName
  #      }
  #      messages {
  #        message
  #      }
  #    }
  #  }
  def create(attrs) do
    user_selection =
      SelectionSet.into(%User{})
      |> SelectionSet.with(:id)
      |> SelectionSet.with(:first_name)
      |> SelectionSet.with(:last_name)

    messages_selection =
      SelectionSet.into([])
      |> SelectionSet.with(:message)

    result_selection =
      SelectionSet.into(%{result: nil, messages: []})
      |> SelectionSet.with(:result, as: user_selection)
      |> SelectionSet.with(:messages, as: messages_selection)

    Graphql.mutation(:createUser, result_selection)
    |> Graphql.arguments(%{user: "UserInput!"})
    |> Graphql.variables(attrs)
  end
end

User.create(%{user: %{first_name: "Thomas", last_name: "Brewer"}})
|> Graphql.execute()
|> case do
  {:ok, user} -> IO.inspect(user)
  {:error, msg} -> IO.inspect(msg)
end

User.get(1)
|> Graphql.execute()
|> case do
  {:ok, user} -> IO.inspect(user)
  {:error, msg} -> IO.inspect(msg)
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/silhouette>.
