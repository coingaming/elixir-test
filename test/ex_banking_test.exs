defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  test "greets the world" do
    assert ExBanking.hello() == :world
  end
end
