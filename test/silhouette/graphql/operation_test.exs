defmodule Silhouette.OperationTest do
  use ExUnit.Case
  doctest Silhouette.Graphql
  alias Silhouette.Graphql
  alias Silhouette.Operation
  alias Fixtures.User
  alias Fixtures.PhoneNumber
  alias Examples.Film
  alias Examples.Launch
  alias Silhouette.SelectionSet

  def setup_simple_user_set(_) do
    selection_set =
      SelectionSet.into(%User{})
      |> SelectionSet.with(:first_name)
      |> SelectionSet.with(:last_name)

    %{simple_user_set: selection_set}
  end

  def setup_simple_user_query(context) do
    Map.put(
      context,
      :simple_user_query,
      Graphql.query(one_of: context[:simple_user_set], for: :user)
    )
  end

  def setup_simple_user_response(context) do
    Map.put(context, :simple_user_response, %{
      "data" => %{"user" => %{"firstName" => "Joe", "lastName" => "Person"}}
    })
  end

  def setup_nested_user_set(_) do
    phone_numbers_selection =
      SelectionSet.into(%PhoneNumber{})
      |> SelectionSet.with(:number)

    selection_set =
      SelectionSet.into(%User{})
      |> SelectionSet.with(:first_name)
      |> SelectionSet.with(:last_name)
      |> SelectionSet.with(:phone_numbers, list_of: phone_numbers_selection)

    %{nested_user_set: selection_set}
  end

  def setup_nested_user_query(context) do
    Map.put(
      context,
      :nested_user_query,
      Graphql.query(one_of: context[:nested_user_set], for: :user)
    )
  end

  def setup_nested_user_response(context) do
    Map.put(context, :nested_user_response, %{
      "data" => %{
        "user" => %{
          "firstName" => "Joe",
          "lastName" => "Person",
          "phoneNumbers" => [%{"number" => "123-123-1234"}, %{"number" => "987-987-9876"}]
        }
      }
    })
  end

  describe "to_graphql/1" do
    setup [:setup_nested_user_set, :setup_nested_user_query]

    test "turns an operation into a graphql query", %{nested_user_query: query} do
      operation =
        query
        |> Graphql.variables(%{id: 1, first_name: "Joe"})
        |> Graphql.arguments(%{id: "ID!", first_name: "String!"})

      assert Operation.to_graphql(operation) ==
               "query User($firstName: String!, $id: ID!) { user(firstName: $firstName, id: $id) { firstName lastName phoneNumbers { number } } }"
    end

    test "turns an operation into a graphql query with top level list" do
      launch_selection =
        SelectionSet.into(%Launch{})
        |> SelectionSet.with(:mission_id)
        |> SelectionSet.with(:mission_name)

      operation = Graphql.query(for: :launches, list_of: launch_selection)

      assert Operation.to_graphql(operation, camelize_names: false) ==
               "query Launches { launches { mission_id mission_name } }"
    end

    test "turns an operation into a graphql query without auto camelizing names", %{
      nested_user_query: query
    } do
      operation =
        query
        |> Graphql.variables(%{id: 1, first_name: "Joe"})
        |> Graphql.arguments(%{id: "ID!", first_name: "String!"})

      assert Operation.to_graphql(operation, camelize_names: false) ==
               "query User($first_name: String!, $id: ID!) { user(first_name: $first_name, id: $id) { first_name last_name phone_numbers { number } } }"
    end

    test "turns an operation into a graphql mutation" do
      user_selection =
        SelectionSet.into(%User{})
        |> SelectionSet.with(:first_name)
        |> SelectionSet.with(:last_name)

      operation =
        Graphql.mutation(one_of: user_selection, for: :create_user)
        |> Graphql.variables(%{id: 1, first_name: "Joe"})
        |> Graphql.arguments(%{id: "ID!", first_name: "String!"})

      assert Operation.to_graphql(operation) ==
               "mutation CreateUser($firstName: String!, $id: ID!) { createUser(firstName: $firstName, id: $id) { firstName lastName } }"
    end
  end

  describe "from_grapqhl/1 when destructing into a struct" do
    setup [:setup_simple_user_set, :setup_simple_user_query, :setup_simple_user_response]

    test "deserializes the response into a User", %{
      simple_user_query: user_query,
      simple_user_response: user_response
    } do
      assert Operation.from_grapqhl(user_query, user_response) == %User{
               first_name: "Joe",
               last_name: "Person"
             }
    end
  end

  describe "from_grapqhl/1 when destructing into nested struct with a list" do
    setup [:setup_nested_user_set, :setup_nested_user_query, :setup_nested_user_response]

    test "deserializes the response into a User with phone_numbers", %{
      nested_user_query: user_query,
      nested_user_response: user_response
    } do
      assert Operation.from_grapqhl(user_query, user_response) == %User{
               first_name: "Joe",
               last_name: "Person",
               phone_numbers: [
                 %PhoneNumber{number: "123-123-1234"},
                 %PhoneNumber{number: "987-987-9876"}
               ]
             }
    end
  end

  describe "from_grapqhl/1 when destructing into nested struct" do
    test "deserializes the response into a User with a phone_number" do
      phone_number_selection =
        SelectionSet.into(%PhoneNumber{})
        |> SelectionSet.with(:number)

      selection_set =
        SelectionSet.into(%User{})
        |> SelectionSet.with(:first_name)
        |> SelectionSet.with(:last_name)
        |> SelectionSet.with(:phone_number, as: phone_number_selection)

      query = Graphql.query(one_of: selection_set, for: :user)

      response = %{
        "data" => %{
          "user" => %{
            "firstName" => "Joe",
            "lastName" => "Person",
            "phoneNumber" => %{"number" => "123-123-1234"}
          }
        }
      }

      assert Operation.from_grapqhl(query, response) == %User{
               first_name: "Joe",
               last_name: "Person",
               phone_number: %PhoneNumber{number: "123-123-1234"}
             }
    end
  end

  describe "from_grapqhl/1 when destructing into a map that contains a list of strings" do
    test "deserializes the response into a map" do
      selection_set =
        SelectionSet.into(%{result: nil, messages: []})
        |> SelectionSet.with(:result, as: :string)
        |> SelectionSet.with(:messages, list_of: :string)

      query = Graphql.query(one_of: selection_set, for: :user)

      response = %{
        "data" => %{
          "user" => %{
            "result" => "Success",
            "messages" => ["Test", "Test2"]
          }
        }
      }

      assert Operation.from_grapqhl(query, response) == %{
               messages: ["Test", "Test2"],
               result: "Success"
             }
    end
  end

  describe "from_grapqhl/1 when destructing into a list" do
    test "deserializes the response into a list" do
      film_selection =
        SelectionSet.into(%Film{})
        |> SelectionSet.with(:title)
        |> SelectionSet.with(:director)

      films_selection =
        SelectionSet.into([])
        |> SelectionSet.with(:films, list_of: film_selection)

      query = Graphql.query(one_of: films_selection, for: :all_films)

      response = %{
        "data" => %{
          "allFilms" => %{
            "films" => [
              %{"title" => "Movie A", "director" => "Joe"},
              %{"title" => "Movie B", "director" => "Jill"}
            ]
          }
        }
      }

      assert Operation.from_grapqhl(query, response) == [
               %Film{director: "Joe", title: "Movie A"},
               %Film{director: "Jill", title: "Movie B"}
             ]
    end
  end

  describe "from_grapqhl/1 when destructing into a top level list" do
    test "deserializes the response into a top level list" do
      launch_selection =
        SelectionSet.into(%Launch{})
        |> SelectionSet.with(:mission_id)
        |> SelectionSet.with(:mission_name)

      query = Graphql.query(for: :launches, list_of: launch_selection)

      response = %{
        "data" => %{
          "launches" => [
            %{"mission_name" => "Mission A", "mission_id" => "1"},
            %{"mission_name" => "Mission B", "mission_id" => "2"}
          ]
        }
      }

      assert Operation.from_grapqhl(query, response, camelize_names: false) == [
               %Launch{mission_id: "1", mission_name: "Mission A"},
               %Launch{mission_id: "2", mission_name: "Mission B"}
             ]
    end
  end
end
