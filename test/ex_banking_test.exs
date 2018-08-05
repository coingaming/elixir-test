defmodule ExBankingTest do
  use ExUnit.Case, async: false
  require IEx
  doctest ExBanking

  test "create user" do
    assert ExBanking.create_user("miguel") == :ok
    assert ExBanking.create_user("miguel") == {:error, :user_already_exists}
  end

  test "deposit" do
    balance = 0.0
    assert ExBanking.get_balance("miguel", "eur") == {:ok, balance}
    balance = balance + 2
    assert ExBanking.deposit("miguel", 2, "eur") == {:ok, balance}
    balance = balance + 3.0
    assert ExBanking.deposit("miguel", 3.0, "eur") == {:ok, balance}
    balance = Float.round(balance + 3.789, 2)
    assert ExBanking.deposit("miguel", 3.789, "eur") == {:ok, balance}
  end

  test "deposit for a user that does not exist" do
    assert ExBanking.deposit("jose", 10, "usd") == {:error, :user_does_not_exist}
  end

  test "get balance" do
    assert ExBanking.get_balance("miguel", "usd") == {:ok, 0.0}
  end

  test "get balance for a user that does not exists" do
    assert ExBanking.get_balance("jose", "usd") == {:error, :user_does_not_exist}
  end

  test "withdraw" do
    assert ExBanking.withdraw("miguel", 0.0, "usd") == {:ok, 0.0}
  end

  test "send" do
    ExBanking.create_user("other")
    assert ExBanking.send("miguel", "other", 0.0, "usd") == {:ok, 0.0, 0.0}
  end
end
