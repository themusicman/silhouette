
# query Launches {
#   launches {
#     mission_name
#     mission_id
#   }
# }

alias Silhouette.SelectionSet
alias Silhouette.Graphql
alias Silhouette.Operation
alias Examples.Launch

launch_selection = SelectionSet.into(%Launch{})
                 |> SelectionSet.with(:mission_id)
                 |> SelectionSet.with(:mission_name)

operation = Graphql.query(for: :launches, list_of: launch_selection)

IO.inspect(query: Operation.to_graphql(operation, camelize_names: false))

