defmodule Silhouette do
  @moduledoc """
  Documentation for `Silhouette`.
  """

  @doc """
  Translates an atom or string to a string in pascal case

  ## Examples

      iex> Silhouette.to_pascal("first_name")
      "FirstName"

      iex> Silhouette.to_pascal(:first_name)
      "FirstName"

  """
  def to_pascal(value) when is_binary(value) do
    Inflex.camelize(value)
  end

  def to_pascal(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> to_pascal()
  end

  @doc """
  Translates an atom or string to a string in camel case

  ## Examples

      iex> Silhouette.to_camel("first_name")
      "firstName"

      iex> Silhouette.to_camel(:first_name)
      "firstName"

  """
  def to_camel(value) when is_binary(value) do
    Inflex.camelize(value, :lower)
  end

  def to_camel(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> to_camel()
  end

  @doc """
  Translates an atom or string to a string 

  ## Examples

      iex> Silhouette.to_string("first_name")
      "first_name"

      iex> Silhouette.to_string(:first_name)
      "first_name"

  """
  def to_string(value) when is_binary(value) do
    value
  end

  def to_string(value) when is_atom(value) do
    Atom.to_string(value)
  end
end
