defmodule FluexTest do
  use ExUnit.Case
  doctest Fluex

  test "greets the world" do
    assert Fluex.hello() == :world
  end
end
