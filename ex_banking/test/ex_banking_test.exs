defmodule ExBankingTest do
  use ExUnit.Case, async: true

  alias Decimal, as: D

  @user "Diego"

  setup_all do
    ExBanking.start_link()
    :ok
  end

  setup do
    on_exit fn ->
      ExBanking.remove_user(@user)
    end
  end

  test "add user" do
    assert :ok == ExBanking.create_user(@user)
  end

  test "does not add existed user" do
    ExBanking.create_user(@user)
    assert {:error, :user_already_exists} == ExBanking.create_user(@user)
  end

  test "increases user's balance" do
    ExBanking.create_user(@user)
    assert {:ok, cast_to_decimal2(100.38)} == ExBanking.deposit(@user, 100.38, 'USD')
  end

  test "casts user's balance to 2 decimal precision" do
    ExBanking.create_user(@user)
    assert {:ok, cast_to_decimal2(100.38)} == ExBanking.deposit(@user, 100.38123, 'USD')
    ExBanking.withdraw(@user, 100.38, 'USD')
    assert {:ok, cast_to_decimal2(100.39)} == ExBanking.deposit(@user, 100.38923, 'USD')
  end

  test "does not increase user's balance" do
    ExBanking.create_user(@user)
    assert {:error, :wrong_arguments} == ExBanking.deposit(@user, -100, 'USD')
  end

  test "returns error when deposit to nonexisting user" do
    ExBanking.create_user(@user)
    assert {:error, :user_does_not_exist} == ExBanking.deposit("Nonexisting", 100, 'USD')
  end

  test "decreases user's balance" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 100, 'USD')
    assert {:ok, cast_to_decimal2(29.66)} == ExBanking.withdraw(@user, 70.34, 'USD')
  end

  test "does not decrease user's balance" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 100, 'USD')
    assert {:error, :wrong_arguments} == ExBanking.withdraw(@user, -70, 'USD')
  end

  test "returns error when withdraw from nonexisting user" do
    ExBanking.create_user(@user)
    assert {:error, :user_does_not_exist} == ExBanking.withdraw("Nonexisting", 70, 'USD')
  end

  test "returns user's balance" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 100.02, 'USD')
    assert {:ok, cast_to_decimal2(100.02)} == ExBanking.get_balance(@user, 'USD')
  end

  test "returns error when ask balance from nonexisting user" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 100, 'USD')
    assert {:error, :user_does_not_exist} == ExBanking.get_balance("Nonexisting", 'USD')
  end

  test "sends amount from user 'a' to user 'b'" do
    ExBanking.create_user(@user)
    ExBanking.deposit(@user, 150, 'USD')
    user_b = "Graham"
    ExBanking.create_user(user_b)
    assert {:ok, cast_to_decimal2(49.93), cast_to_decimal2(100.07)} == ExBanking.send(@user, user_b, 100.07, 'USD')
  end

  test "does not send amount from user if it more than it has" do
    ExBanking.create_user(@user)
    user_b = "Graham"
    ExBanking.create_user(user_b)
    assert {:error, :not_enough_money} == ExBanking.send(@user, user_b, 100.07, 'USD')
  end

  defp cast_to_decimal2(amount) do
    amount |> D.new() |> D.round(2)
  end
end
