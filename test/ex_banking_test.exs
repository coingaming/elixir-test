defmodule ExBankingTest do
  use ExUnit.Case, async: true
  alias Decimal
  doctest ExBanking

  @first_user "first user"
  @second_user "second user"

  setup_all do
    ExBanking.create_user(@first_user)
    ExBanking.create_user(@second_user)

    :ok
  end

  test "create user" do
    assert :ok == ExBanking.create_user("user")
  end

  test "user already exists" do
    assert {:error, :user_already_exists} ==
             ExBanking.create_user(@first_user)
  end

  test "deposit" do
    assert {:ok, balance} = ExBanking.get_balance(@first_user, "eur")
    assert {:ok, balance} = ExBanking.deposit(@first_user, 2.0, "eur")
  end

  test "deposit for a user that does not exist" do
    assert {:error, :user_does_not_exist} ==
             ExBanking.deposit("Not existing user", 10, "usd")
  end

  test "get balance" do
    assert {:ok, balance} = ExBanking.get_balance(@first_user, "usd")
  end

  test "get balance for a user that does not exists" do
    assert {:error, :user_does_not_exist} ==
             ExBanking.get_balance("Not existing user", "usd")
  end

  test "withdrawal of the user bank account not enough money" do
    {:ok, balance} = ExBanking.get_balance(@first_user, "usd")
    withdraw_amt = balance + 1.0

    assert {:error, :not_enough_money} ==
             ExBanking.withdraw(@first_user, withdraw_amt, "usd")
  end

  test "withdrawal of the user bank account" do
    assert {:ok, _deposit_amt} = ExBanking.deposit(@first_user, 10.0, "usd")
    assert {:ok, balance} = ExBanking.withdraw(@first_user, 5.0, "usd")
  end

  test "withdrawal for a user that does not exists" do
    assert {:error, :user_does_not_exist} ==
             ExBanking.withdraw("Not existing user", 1.0, "usd")
  end

  test "send money from a user that does not exists" do
    assert {:error, :sender_does_not_exist} ==
             ExBanking.send("Not existing user", @second_user, 10.0, "usd")
  end

  test "send money from user with not enough money" do
    assert {:error, :not_enough_money} ==
             ExBanking.send(@first_user, @second_user, 100.0, "usd")
  end

  test "send money to user that does not exists" do
    ExBanking.deposit(@first_user, 1.0, "usd")

    assert {:error, :receiver_does_not_exist} ==
             ExBanking.send(@first_user, "Not existing user", 1.0, "usd")
  end

  test "send money" do
    ExBanking.deposit(@first_user, 10.0, "usd")
    {_, balance} = ExBanking.get_balance(@first_user, "usd")
    withdraw_amt = 5.0
    new_balance = balance - withdraw_amt

    assert {:ok, new_balance, withdraw_amt} ==
             ExBanking.send(@first_user, @second_user, withdraw_amt, "usd")
  end

  test "limit transfer request" do
    ExBanking.create_user("first_user_limit")
    ExBanking.create_user("second_user_limit")
    ExBanking.deposit("first_user_limit", 1000.00, "usd")
    ExBanking.deposit("second_user_limit", 1000.00, "usd")
    # Test limit request for sender
    1..800
    |> Enum.each(fn _ ->
      spawn(fn ->
        ExBanking.deposit("first_user_limit", 1.0, "usd")
      end)
    end)

    assert {:error, :too_many_requests_to_sender} ==
             ExBanking.send("first_user_limit", "second_user_limit", 1.0, "usd")

    # Test lmit request for receiver
    1..1_000
    |> Enum.each(fn _ ->
      spawn(fn ->
        ExBanking.deposit("second_user_limit", 1.0, "usd")
      end)
    end)

    assert {:error, :too_many_requests_to_receiver} ==
             ExBanking.send("first_user_limit", "second_user_limit", 1.0, "usd")
  end

  test "limit requests" do
    ExBanking.create_user("third_user_limit")

    1..800
    |> Enum.each(fn _ -> spawn(fn -> ExBanking.deposit("third_user_limit", 1.0, "usd") end) end)

    assert ExBanking.get_balance("third_user_limit", "usd") ==
             {:error, :too_many_requests_to_user}
  end

  test "negative amount not allowed" do
    assert ExBanking.deposit(@first_user, -1.0, "usd") == {:error, :wrong_arguments}
    assert ExBanking.send(@first_user, @second_user, -10.0, "usd") == {:error, :wrong_arguments}
    assert ExBanking.withdraw(@second_user, -10.0, "usd") == {:error, :wrong_arguments}
  end
end
