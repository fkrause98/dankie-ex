defmodule DankieTest do
  use ExUnit.Case
  doctest Dankie

  test "greets the world" do
    assert Dankie.hello() == :world
  end
end
