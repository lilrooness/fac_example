defmodule FacExampleTest do
  use ExUnit.Case
  doctest FacExample

  test "greets the world" do
    assert FacExample.hello() == :world
  end
end
