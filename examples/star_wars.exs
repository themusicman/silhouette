alias Silhouette.SelectionSet
alias Silhouette.Graphql
alias Examples.Film

# query AllFilms {
#  allFilms {
#     films {
#       title
#       director
#     }
#   }
# }

film_selection = SelectionSet.into(%Film{})
                 |> SelectionSet.with(:title)
                 |> SelectionSet.with(:director)
                 |> SelectionSet.with(:release_data)

films_selection = SelectionSet.into([])
            |> SelectionSet.with(:films, list_of: film_selection)


operation = Graphql.query(for: :all_films, one_of: films_selection)
            |> Graphql.url("https://swapi-graphql.netlify.app/.netlify/functions/index")

case Graphql.execute(operation) do
  {:ok, data} -> IO.inspect(data: data)
  {:error, reason} -> IO.inspect(reason: reason)
end
