defmodule Silhouette.GraphqlTest do
  use ExUnit.Case
  doctest Silhouette.Graphql
  alias Silhouette.Graphql
  alias Silhouette.Operation
  alias Fixtures.User
  alias Fixtures.PhoneNumber
  alias Silhouette.SelectionSet

  def setup_set(_) do
    phone_number_selection =
      SelectionSet.into(%PhoneNumber{})
      |> SelectionSet.with(:number)

    selection_set =
      SelectionSet.into(%User{})
      |> SelectionSet.with(:phone_numbers, list_of: phone_number_selection)
      |> SelectionSet.with(:first_name)
      |> SelectionSet.with(:last_name)

    %{set: selection_set}
  end

  def setup_query(context) do
    Map.put(context, :query, Graphql.query(one_of: context[:set], for: :user))
  end

  describe "query/2" do
    setup [:setup_set, :setup_query]

    test "creates an operation struct with type set to query", %{query: query} do
      %Operation{type: type} = query
      assert type == :query
    end

    test "creates an operation struct with selection_set set", %{query: query, set: set} do
      %Operation{opts: %{one_of: selection_set}} = query
      assert selection_set == set
    end

    test "creates an operation struct with opts contains for option", %{query: query} do
      %Operation{opts: %{for: for_value}} = query
      assert for_value == :user
    end
  end

  describe "mutation/2" do
    setup [:setup_set]

    test "creates an operation struct with type set to mutation", %{set: set} do
      %Operation{type: type} = Graphql.mutation(one_of: set, for: :user)
      assert type == :mutation
    end

    test "creates an operation struct with selection_set set", %{set: set} do
      %Operation{opts: %{one_of: selection_set}} = Graphql.mutation(one_of: set, for: :user)
      assert selection_set == set
    end

    test "creates an operation struct with opts contains for option", %{set: set} do
      expected_for_value = :user
      %Operation{opts: %{for: for_value}} = Graphql.mutation(one_of: set, for: expected_for_value)
      assert for_value == expected_for_value
    end
  end

  describe "variables/2" do
    setup [:setup_set, :setup_query]

    test "sets the variables for the operation", %{query: query} do
      expected_variables = %{test: 1}
      operation = Graphql.variables(query, expected_variables)
      assert operation.variables == expected_variables
    end
  end

  describe "headers/2" do
    setup [:setup_set, :setup_query]

    test "merges existing headers in the operation with new headers", %{query: query} do
      operation = Graphql.headers(query, %{"Authorization" => "Bearer mytoken"})

      assert operation.opts[:headers] == %{
               "Content-Type" => "application/json",
               "Authorization" => "Bearer mytoken"
             }
    end
  end

  describe "url/2" do
    setup [:setup_set, :setup_query]

    test "replaces the existing url option", %{query: query} do
      expected_url = "https://example.com/graphql"
      operation = Graphql.url(query, expected_url)

      assert operation.opts[:url] == expected_url
    end
  end
end
