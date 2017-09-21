# elixir-test

Test task for Elixir developers. Candidate should write a simple banking OTP application in Elixir language.

### General acceptance criteria

- All code is in `git` repo (candidate can use his/her own github account).
- OTP application is a standard `mix` project.
- Application name is `:ex_banking` (main Elixir module is `ExBanking`).
- Application interface is just set of public functions of `ExBanking` module (no API endpoint, no REST / SOAP API etc ..).
- Application should `not` use any database / disc storage. All needed data should be stored only in application memory.
- Candidate can use any Elixir or Erlang library he/she wants to.

### Money amounts

- Money amount of any currency should `not` be negative.
- Application should provide `2 decimal` precision of money amount for any currency.
- Amount of money incoming to the system should be equal to amount of money inside the system + amount of withdraws (money should not appear or disappear accidentally).
- User and currency type is any string. Case sensitive. New currencies / users can be added dynamically in runtime.

### API reference

Requirements for public functions provided by `ExBanking` module. Any function should return success result or error result. Success result is different for each function, error result is generic

```
@type banking_error :: {:error,
    :wrong_arguments                |
    :user_already_exists            |
    :user_does_not_exist            |
    :not_enough_money               |
    :sender_does_not_exist          |
    :receiver_does_not_exist        |
    :too_many_requests_to_user      |
    :too_many_requests_to_sender    |
    :too_many_requests_to_receiver
  }
```

*@spec create_user(user :: String.t) :: :ok | banking_error*

- Function creates new user in the system
- New user has zero balance of any currency

*@spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error*

- Increases user's balance in given `currency` by `amount` value
- Returns `new_balance` of the user in given format

*@spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error*

- Decreases user's balance in given `currency` by `amount` value
- Returns `new_balance` of the user in given format

*@spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | banking_error*

- Returns `balance` of the user in given format

*@spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error*

- Decreases `from_user`'s balance in given `currency` by `amount` value
- Increases `to_user`'s balance in given `currency` by `amount` value
- Returns `balance` of `from_user` and `to_user` in given format

### Performance

In every single moment of time the system should handle 10 or less operations for every individual user (user is a string passed as the first argument to API functions). If there is any new operation for a user and he/she still has 10 operations in pending state - new operation should immediately return `too_many_requests_to_user` error until number of requests for this user decreases < 10.
