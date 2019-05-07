defmodule BulletinTest do
  use ExUnit.Case
  doctest Bulletin

  test "greets the world" do
    assert Bulletin.hello() == :world
  end
end
