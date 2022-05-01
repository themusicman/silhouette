# query Launches {
#   launches {
#     mission_name
#     mission_id
#     rocket {
#       rocket_name
#       rocket {
#         company
#         name
#         mass {
#           kg
#         }
#       }
#     }
#     launch_site {
#       site_name
#     }
#     launch_date_local
#   }
# }

alias Silhouette.SelectionSet
alias Silhouette.Graphql
alias Examples.Launch

launch_selection = SelectionSet.into(%Launch{})
                 |> SelectionSet.with(:ten)
                 |> SelectionSet.with(:mission_name)

operation = Graphql.query(for: :launches, list_of: launch_selection)
            |> Graphql.url("https://api.spacex.land/graphql/")

case Graphql.execute(operation, [query_opts: [camelize_names: false]]) do
  {:ok, data} -> IO.inspect(data: data)
  {:error, reason} -> IO.inspect(reason: reason)
end
