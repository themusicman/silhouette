defmodule Silhouette.Operation do
  defstruct type: :query,
            variables: %{},
            arguments: %{},
            opts: %{}

  alias __MODULE__
  alias Silhouette.SelectionSet
  alias Silhouette.Selection
  alias Silhouette.Graphql

  @type t :: %__MODULE__{}

  def new(attrs) do
    struct!(Operation, attrs)
    |> Graphql.headers(%{"Content-Type" => "application/json"})
  end

  def selection_set(%Operation{opts: %{list_of: selection_set}}) do
    selection_set
  end

  def selection_set(%Operation{opts: %{one_of: selection_set}}) do
    selection_set
  end

  def to_graphql(%Operation{type: type} = operation, query_opts \\ []) do
    field = Selection.field(operation.opts[:for], query_opts)

    name = Silhouette.to_pascal(field)

    selection =
      operation
      |> selection_set()
      |> SelectionSet.to_graphql(query_opts)

    # TODO: Do some checking to see if we have arguments without variable values

    arguments =
      if Enum.empty?(operation.arguments) do
        ""
      else
        "(" <>
          (Enum.map(operation.arguments, fn {arg, val} ->
             "$#{Selection.field(arg, query_opts)}: #{val}"
           end)
           |> Enum.join(", ")) <> ")"
      end

    variables =
      if Enum.empty?(operation.variables) do
        ""
      else
        "(" <>
          (Enum.map(operation.variables, fn {arg, _} ->
             "#{Selection.field(arg, query_opts)}: $#{Selection.field(arg, query_opts)}"
           end)
           |> Enum.join(", ")) <> ")"
      end

    # TODO: Need to rework how variables are handled
    "#{Atom.to_string(type)} #{name}#{arguments} { #{field}#{variables} #{selection} }"
  end

  def from_grapqhl(operation, response, query_opts \\ [camelize_names: true]) do
    operation
    |> selection_set()
    |> SelectionSet.from_grapqhl(operation, response, query_opts)
  end
end
