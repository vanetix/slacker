defmodule SlackerBackendTest do
  use ExUnit.Case
  doctest SlackerBackend

  test "greets the world" do
    assert SlackerBackend.hello() == :world
  end
end
