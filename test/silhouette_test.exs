defmodule SilhouetteTest do
  use ExUnit.Case
  doctest Silhouette

  test "greets the world" do
    assert Silhouette.hello() == :world
  end
end
