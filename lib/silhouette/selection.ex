defmodule Silhouette.Selection do
  defstruct field: "", opts: %{}

  alias __MODULE__
  alias Silhouette.SelectionSet

  @type t :: %__MODULE__{}

  def new(attrs) do
    struct!(Selection, attrs)
  end

  @doc """
  Possibly transforms a string into a camelized version based on options

  ## Examples

      iex> Silhouette.Selection.field("first_name", [camelize_names: true])
      "firstName"

      iex> Silhouette.Selection.field("first_name", [camelize_names: false])
      "first_name"

  """
  def field(field, opts) do
    if opts[:camelize_names] == false do
      Silhouette.to_string(field)
    else
      Silhouette.to_camel(field)
    end
  end

  def to_graphql(%Selection{field: field, opts: %{list_of: selection_set}}, query_opts) do
    selection_set_to_graphql(field, selection_set, query_opts)
  end

  def to_graphql(%Selection{field: field, opts: %{as: selection_set}}, query_opts)
      when is_struct(selection_set) do
    selection_set_to_graphql(field, selection_set, query_opts)
  end

  def to_graphql(%Selection{field: field}, query_opts) do
    field(field, query_opts)
  end

  def from_grapqhl(
        %Selection{opts: %{list_of: %SelectionSet{} = selection_set}} = selection,
        operation,
        data,
        query_opts
      ) do
    data[field(selection.field, query_opts)]
    |> Enum.reduce([], fn datum, acc ->
      value = SelectionSet.insert_into(selection_set, operation, datum, query_opts)
      [value | acc]
    end)
    |> Enum.reverse()
  end

  # TODO: better support other scalar data types
  def from_grapqhl(%Selection{opts: %{list_of: data_type}} = selection, _, data, query_opts)
      when data_type == :string do
    data[field(selection.field, query_opts)]
    |> Enum.reduce([], fn datum, acc ->
      [datum | acc]
    end)
    |> Enum.reverse()
  end

  def from_grapqhl(
        %Selection{opts: %{as: selection_set}} = selection,
        operation,
        data,
        query_opts
      )
      when is_struct(selection_set) do
    SelectionSet.insert_into(
      selection_set,
      operation,
      data[field(selection.field, query_opts)],
      query_opts
    )
  end

  # TODO: better support other scalar data types
  def from_grapqhl(selection, _, data, query_opts) do
    data[field(selection.field, query_opts)]
  end

  defp selection_set_to_graphql(field, selection_set, query_opts) do
    [
      field(field, query_opts),
      SelectionSet.to_graphql(selection_set, query_opts)
    ]
    |> Enum.join(" ")
  end
end
