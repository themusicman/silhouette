defmodule Silhouette.SelectionSet do
  @moduledoc """
  A SelectionSet defines the fields that are being queried and the Elixir data structure the results are put into.
  """
  defstruct into: nil, selections: %{}

  alias __MODULE__
  alias Silhouette.Operation
  alias Silhouette.Selection

  @type t :: %__MODULE__{}

  def new(attrs) do
    struct!(SelectionSet, attrs)
  end

  def into(data_type) do
    SelectionSet.new(%{into: data_type})
  end

  def with(set, field, opts \\ []) when is_atom(field) do
    opts = Enum.into(opts, %{})

    opts =
      if Map.has_key?(opts, :as) do
        opts
      else
        Map.merge(opts, %{as: :string})
      end

    selection = Selection.new(%{field: field, opts: opts})
    %{set | selections: Map.put(set.selections, field, selection)}
  end

  def without(set, field) when is_atom(field) do
    %{set | selections: Map.drop(set.selections, [field])}
  end

  def to_graphql(set, query_opts \\ []) do
    "{ " <>
      (Map.values(set.selections)
       |> Enum.map(fn selection -> Selection.to_graphql(selection, query_opts) end)
       |> Enum.join(" ")) <> " }"
  end

  def from_grapqhl(selection_set, operation, response, query_opts) do
    field = Selection.field(operation.opts[:for], query_opts)
    data = get_in(response, ["data", field])
    insert_into(selection_set, operation, data, query_opts)
  end

  def insert_into(
        _,
        %Operation{opts: %{list_of: selection_set}} = operation,
        data,
        query_opts
      )
      when is_list(data) do
    data
    |> Enum.map(fn datum ->
      insert_into(selection_set, operation, datum, query_opts)
    end)
  end

  def insert_into(selection_set, operation, data, query_opts)
      when is_struct(selection_set.into) do
    data =
      selection_set.selections
      |> Map.values()
      |> Enum.reduce(%{}, fn s, acc ->
        value = Selection.from_grapqhl(s, operation, data, query_opts)
        Map.put(acc, s.field, value)
      end)

    struct(selection_set.into, data)
  end

  def insert_into(selection_set, operation, data, query_opts) when is_map(selection_set.into) do
    data =
      selection_set.selections
      |> Map.values()
      |> Enum.reduce(%{}, fn s, acc ->
        value = Selection.from_grapqhl(s, operation, data, query_opts)
        Map.put(acc, s.field, value)
      end)

    Map.merge(selection_set.into, data)
  end

  def insert_into(selection_set, operation, data, query_opts) when is_list(selection_set.into) do
    selection_set.selections
    |> Map.values()
    |> Enum.flat_map(fn s ->
      Selection.from_grapqhl(s, operation, data, query_opts)
    end)
  end
end
