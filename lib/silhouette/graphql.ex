defmodule Silhouette.Graphql do
  alias Silhouette.Operation

  def query(opts \\ []) do
    build_operation(:query, opts)
  end

  def mutation(opts \\ []) do
    build_operation(:mutation, opts)
  end

  defp build_operation(type, opts) do
    Operation.new(%{type: type, opts: Enum.into(opts, %{})})
  end

  def variables(operation, vars) do
    %{operation | variables: vars}
  end

  def arguments(operation, args) do
    %{operation | arguments: args}
  end

  def headers(operation, headers) do
    headers =
      if Map.has_key?(operation.opts, :headers) do
        Map.merge(operation.opts[:headers], headers)
      else
        headers
      end

    %{operation | opts: Map.put(operation.opts, :headers, headers)}
  end

  def url(operation, url) do
    %{operation | opts: Map.put(operation.opts, :url, url)}
  end

  def execute(operation, opts \\ []) do
    query_opts = opts[:query_opts]
    query = Operation.to_graphql(operation, query_opts)

    body = %{query: query, variables: operation.variables} |> Jason.encode!()
    headers = operation.opts[:headers]

    headers =
      if Keyword.has_key?(opts, :headers) do
        Map.merge(headers, opts[:headers])
      else
        headers
      end

    url = operation.opts[:url]

    url =
      if Keyword.has_key?(opts, :url) do
        opts[:url]
      else
        url
      end

    case HTTPoison.post(url, body, Map.to_list(headers)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Operation.from_grapqhl(operation, Jason.decode!(body), query_opts)}

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        {:error, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
        {:error, reason}
    end
  end
end
