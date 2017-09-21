# elixir-test

Test task for Elixir developers. Candidate should write simple banking OTP application in Elixir language.

### General acceptance criteria

- All code is in `git` repo (candidate can use his own github account).
- OTP application is standard `mix` project.
- Application name is `:ex_banking` (main Elixir module is `ExBanking`).
- Application interface is just set of public functions of `ExBanking` module (no API endpoint, no REST / SOAP API etc ..).
- `ExUnit` should be used for writing tests.
- Application should have 100% test coverage.
- Application should `not` use any database / disc storage. All needed data should be stored only in application memory.
- Candidate can use any Elixir or Erlang library he wants.

### Money amounts

- Money amount of any currency should `not` be negative.
- Application should provide `2 decimal` precision of money amount for any currency.
- Amount of money incoming to the system should be equal to amount of money inside the system + amount of withdraws (money should not appear or disappear accidentally).
- User and currency type is any string. Case sensitive. New currencies / users can be added dynamically in runtime.

### API reference

Requirements for public functions provided by `ExBanking` module. Any function should return success result or error result. Success result is various for each function, error result is generic

```
@type banking_error :: {:error,
    :wrong_arguments         |
    :user_is_already_exist   |
    :user_is_not_exist       |
    :not_enough_money        |
    :sender_is_not_exist     |
    :receiver_is_not_exist   |
    :user_is_overloaded      |
    :sender_is_overloaded    |
    :receiver_is_overloaded
  }
```

*@spec create_user(user :: String.t) :: :ok | banking_error*

- Function creates new user in the system
- New user has zero balance of any currency

*@spec remove_user(user :: String.t) :: :ok | banking_error*

- Function totally removes user (and his money) from the system

*@spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error*

- Increases user's balance of given `currency` by `amount` value
- Returns `new_balance` of user in given format

*@spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error*

- Decreases user's balance of given `currency` by `amount` value
- Returns `new_balance` of user in given format

*@spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | banking_error*

- Returns `balance` of user in given format

*@spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error*

- Decreases `from_user`'s balance of given `currency` by `amount` value
- Increases `to_user`'s balance of given `currency` by `amount` value
- Returns `balance` of `from_user` and `to_user` in given format

### Performance

In every single moment of time the system should handle 10 or less operations for every individual user (it means user is string passed as first argument to API functions). If there is any new operation for user and he still has 10 operations in pending state - new operation should immediately return `user_is_overloaded` error until number of requests for this user decreases < 10.
