defmodule DsmTest do
  use ExUnit.Case
  doctest Dsm

  test "greets the world" do
    assert Dsm.hello() == :world
  end
end
