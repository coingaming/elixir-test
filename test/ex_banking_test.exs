defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  test "create user" do
    assert ExBanking.create_user("miguel") == :ok
  end

  test "deposit" do
    assert ExBanking.deposit("miguel", 0.0, "$") == {:ok, 0.0}
  end

  test "withdraw" do
    assert ExBanking.withdraw("miguel", 0.0, "$") == {:ok, 0.0}
  end

  test "get balance" do
    assert ExBanking.get_balance("miguel", "$") == {:ok, 0.0}
  end

  test "send" do
    ExBanking.create_user("other")
    assert ExBanking.send("miguel", "other", 0.0, "$") == {:ok, 0.0, 0.0}
  end
end
