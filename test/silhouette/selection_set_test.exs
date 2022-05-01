defmodule Silhouette.SelectionSetTest do
  use ExUnit.Case
  doctest Silhouette.SelectionSet
  alias Silhouette.SelectionSet
  alias Fixtures.User
  alias Fixtures.PhoneNumber
  alias Fixtures.Film

  def setup_set(_) do
    %{set: SelectionSet.into(%User{})}
  end

  describe "into/1" do
    setup [:setup_set]

    test "creates SelectionSet struct", %{set: set} do
      assert set.__struct__ == Silhouette.SelectionSet
    end

    test "sets the into field", %{set: set} do
      assert set.into.__struct__ == Fixtures.User
    end
  end

  describe "with/1" do
    setup [:setup_set]

    test "adds a selection to the set", %{set: set} do
      set = SelectionSet.with(set, :first_name)
      assert Enum.count(set.selections) == 1
    end

    test "sets the field on the selection", %{set: set} do
      set = SelectionSet.with(set, :first_name)
      assert set.selections[:first_name].field == :first_name
    end

    test "sets the default as option to :string", %{set: set} do
      set = SelectionSet.with(set, :first_name)
      assert set.selections[:first_name].opts[:as] == :string
    end

    test "sets the as option to value passed", %{set: set} do
      set = SelectionSet.with(set, :created_at, as: :datetime)
      assert set.selections[:created_at].opts[:as] == :datetime
    end

    test "sets the list_of option", %{set: set} do
      phone_numbers_selection = SelectionSet.into(%PhoneNumber{})
      set = SelectionSet.with(set, :phone_numbers, list_of: phone_numbers_selection)
      assert set.selections[:phone_numbers].opts[:list_of] == phone_numbers_selection
    end
  end

  describe "to_graphql/1" do
    setup [:setup_set]

    test "creates produces a string containing all the fields in the selection set", %{set: set} do
      set =
        set
        |> SelectionSet.with(:first_name)
        |> SelectionSet.with(:last_name)

      assert SelectionSet.to_graphql(set) == "{ firstName lastName }"
    end

    test "creates produces a string containing all the fields in the selection set recursively when there is a selection set in the as option",
         %{set: set} do
      phone_number_selection =
        SelectionSet.into(%PhoneNumber{})
        |> SelectionSet.with(:number)

      set =
        set
        |> SelectionSet.with(:first_name)
        |> SelectionSet.with(:last_name)
        |> SelectionSet.with(:phone_number, as: phone_number_selection)

      assert SelectionSet.to_graphql(set) == "{ firstName lastName phoneNumber { number } }"
    end

    test "creates produces a string containing all the fields in the selection set recursively when there is a selection set in the list_of option",
         %{set: set} do
      phone_number_selection =
        SelectionSet.into(%PhoneNumber{})
        |> SelectionSet.with(:number)

      set =
        set
        |> SelectionSet.with(:first_name)
        |> SelectionSet.with(:last_name)
        |> SelectionSet.with(:phone_numbers, list_of: phone_number_selection)

      assert SelectionSet.to_graphql(set) == "{ firstName lastName phoneNumbers { number } }"
    end

    test "produces a string selecting a list of items" do
      film_selection =
        SelectionSet.into(%Film{})
        |> SelectionSet.with(:title)
        |> SelectionSet.with(:director)

      set =
        SelectionSet.into([])
        |> SelectionSet.with(:films, list_of: film_selection)

      assert SelectionSet.to_graphql(set) == "{ films { director title } }"
    end
  end
end
