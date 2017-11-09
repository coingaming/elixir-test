defmodule ExBanking do
  use GenServer

  alias Decimal, as: D

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

  ### GenServer API

  def init(state) do
    {:ok, state}
  end

  def handle_call(:users, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:deposit, user, amount, currency}, _from, state) do
    state = add_amount(state, user, amount)
    {:reply, {:ok, state[user].balance}, state}
  end

  def handle_call({:withdraw, user, amount, currency}, _from, state) do
    state = subtract_amount(state, user, amount)
    {:reply, {:ok, state[user].balance}, state}
  end

  def handle_call({:get_balance, user, currency}, _from, state) do
    {:reply, {:ok, state[user].balance}, state}
  end

  def handle_call({:send, from_user, to_user, amount, currency}, _from, state) do
    state = subtract_amount(state, from_user, amount)
    state = add_amount(state, to_user, amount)
    {:reply, {:ok, state[from_user].balance, state[to_user].balance}, state}
  end

  def handle_cast({:create_user, user}, state) do
    {:noreply, Map.put(state, user, %{balance: 0.00, currency: 'USD'})}
  end

  def handle_cast({:remove_user, user}, state) do
    {:noreply, Map.delete(state, user)}
  end

  ### Client API / Helper functions

  def start_link(state \\ %{}) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def users, do: GenServer.call(__MODULE__, :users)

  def remove_user(user), do: GenServer.cast(__MODULE__, {:remove_user, user})

  @spec create_user(user :: String.t) :: :ok | banking_error
  def create_user(user) do
    if users()[user] do
      {:error, :user_already_exists}
    else
      GenServer.cast(__MODULE__, {:create_user, user})
    end
  end

  @spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency) when amount >= 0 do
    if users()[user] do
      GenServer.call(__MODULE__, {:deposit, user, cast_to_decimal2(amount), currency})
    else
      {:error, :user_does_not_exist}
    end
  end
  def deposit(_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end

  @spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency) when amount >= 0 do
    if users()[user] do
      GenServer.call(__MODULE__, {:withdraw, user, cast_to_decimal2(amount), currency})
    else
      {:error, :user_does_not_exist}
    end
  end
  def withdraw(_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end

  @spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | banking_error
  def get_balance(user, currency) do
    if users()[user] do
      GenServer.call(__MODULE__, {:get_balance, user, currency})
    else
      {:error, :user_does_not_exist}
    end
  end

  @spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency) when amount >= 0 do
    if users()[from_user] do
      if users()[to_user] do
        {:ok, from_balance} = get_balance(from_user, currency)
        if from_balance >= cast_to_decimal2(amount) do
          GenServer.call(__MODULE__, {:send, from_user, to_user, cast_to_decimal2(amount), currency})
        else
          {:error, :not_enough_money}
        end
      else
        {:error, :receiver_does_not_exist}
      end
    else
      {:error, :sender_does_not_exist}
    end
  end
  def send(_from_user, _to_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end

  defp add_amount(state, user, amount) do
    update_in(state[user].balance, &(D.add(D.new(&1), D.new(amount))))
  end

  defp subtract_amount(state, user, amount) do
    update_in(state[user].balance, &(D.sub(D.new(&1), D.new(amount))))
  end

  defp cast_to_decimal2(amount) do
    amount |> D.new() |> D.round(2)
  end
end
