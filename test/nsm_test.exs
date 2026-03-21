defmodule NsmTest do
  use ExUnit.Case
  doctest Nsm

  test "greets the world" do
    assert Nsm.hello() == :world
  end
end
