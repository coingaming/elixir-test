defmodule ExBankingTest do
  use ExUnit.Case, async: false
  require IEx
  doctest ExBanking

  test "create user" do
    assert ExBanking.create_user("user1") == :ok
    assert ExBanking.create_user("user1") == {:error, :user_already_exists}
  end

  test "deposit" do
    assert ExBanking.create_user("user2") == :ok
    balance = 0.0
    assert ExBanking.get_balance("user2", "eur") == {:ok, balance}
    balance = balance + 2
    assert ExBanking.deposit("user2", 2, "eur") == {:ok, balance}
    balance = balance + 3.0
    assert ExBanking.deposit("user2", 3.0, "eur") == {:ok, balance}
    balance = Float.round(balance + 3.789, 2)
    assert ExBanking.deposit("user2", 3.789, "eur") == {:ok, balance}
  end

  test "deposit for a user that does not exist" do
    assert ExBanking.deposit("user4", 10, "usd") == {:error, :user_does_not_exist}
  end

  test "get balance" do
    assert ExBanking.create_user("user3") == :ok
    balance = Float.round(3.789, 2)
    assert ExBanking.deposit("user3", 3.789, "usd") == {:ok, balance}
    assert ExBanking.get_balance("user3", "usd") == {:ok, balance}
  end

  test "get balance for a user that does not exists" do
    assert ExBanking.get_balance("user4", "usd") == {:error, :user_does_not_exist}
  end

  test "withdraw" do
    assert ExBanking.withdraw("user1", 0.0, "usd") == {:ok, 0.0}
  end

  test "send" do
    ExBanking.create_user("user5")
    assert ExBanking.send("user5", "user5", 0.0, "usd") == {:ok, 0.0, 0.0}
  end
end
