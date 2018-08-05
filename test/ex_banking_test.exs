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
    assert ExBanking.deposit("user3", 10, "usd") == {:error, :user_does_not_exist}
  end

  test "get balance" do
    assert ExBanking.create_user("user4") == :ok
    balance = Float.round(3.789, 2)
    assert ExBanking.deposit("user4", 3.789, "usd") == {:ok, balance}
    assert ExBanking.get_balance("user4", "usd") == {:ok, balance}
  end

  test "get balance for a user that does not exists" do
    assert ExBanking.get_balance("user5", "usd") == {:error, :user_does_not_exist}
  end

  test "withdrawal of the user bank account" do
    assert ExBanking.create_user("user6") == :ok
    deposit_amount = 10
    withdraw_amount = 5
    assert ExBanking.withdraw("user6", withdraw_amount, "usd") == {:error, :not_enough_money}
    assert ExBanking.deposit("user6", deposit_amount, "usd") == {:ok, deposit_amount}
    balance = Float.round(deposit_amount / 1 - withdraw_amount, 2)
    assert ExBanking.withdraw("user6", withdraw_amount, "usd") == {:ok, balance}
    assert ExBanking.get_balance("user6", "usd") == {:ok, balance}
    assert ExBanking.get_balance("user6", "eur") == {:ok, 0.0}
    assert ExBanking.withdraw("user7", withdraw_amount, "usd") == {:error, :user_does_not_exist}
  end

  test "send" do
    assert ExBanking.send("user_from", "user_to", 10.0, "usd") == {:error, :sender_does_not_exist}
    ExBanking.create_user("user_from")
    assert ExBanking.send("user_from", "user_to", 10.0, "usd") == {:error, :not_enough_money}
    assert ExBanking.deposit("user_from", 20.0, "usd") == {:ok, 20.0}

    assert ExBanking.send("user_from", "user_to", 10.0, "usd") ==
             {:error, :receiver_does_not_exist}

    ExBanking.create_user("user_to")
    assert ExBanking.send("user_from", "user_to", 5.0, "usd") == {:ok, 15.0, 5.0}
    assert ExBanking.get_balance("user_from", "usd") == {:ok, 15.0}
    assert ExBanking.get_balance("user_to", "usd") == {:ok, 5.0}
  end

  test "limit requests" do
    ExBanking.create_user("user8")
    1..800_000 |> Enum.each(fn _ -> spawn(fn -> ExBanking.deposit("user8", 1, "usd") end) end)
    assert ExBanking.get_balance("user8", "usd") == {:error, :too_many_requests_to_user}
    ExBanking.create_user("user9")
    assert ExBanking.get_balance("user9", "usd") == {:ok, 0.0}
  end

  test "limit transfer request" do
    ExBanking.create_user("user10")
    ExBanking.create_user("user11")
    # Test limit request fof sender
    1..800_000 |> Enum.each(fn _ -> spawn(fn -> ExBanking.deposit("user10", 1, "usd") end) end)

    assert ExBanking.send("user10", "user11", 100, "usd") ==
             {:error, :too_many_requests_to_sender}

    # Test lmit request for receiver
    1..800_000 |> Enum.each(fn _ -> spawn(fn -> ExBanking.deposit("user11", 1, "usd") end) end)

    assert ExBanking.send("user10", "user11", 100, "usd") ==
             {:error, :too_many_requests_to_receiver}
  end
end
