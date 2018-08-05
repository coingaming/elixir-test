defmodule ExBanking.Registry do
  use GenServer
  alias ExBanking.Bucket
  require IEx

  ## Client API

  @doc """
  Starts the registry with te given options

  `name` is always required
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @doc """
  Creates a new bank account for user
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  @doc """
  Increase balance in the user account
  """
  def deposit(server, name, amount, currency) do
    GenServer.call(server, {:deposit, name, amount, currency})
  end

  @doc """
  Get the balance for the user and currency specified
  """
  def get_balance(server, name, currency) do
    GenServer.call(server, {:get_balance, name, currency})
  end

  @doc """
  Withdraw the specified amount from the user balance in the specified currency
  """
  def withdraw(server, name, amount, currency) do
    GenServer.call(server, {:withdaw, name, amount, currency})
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    refs = %{}
    accounts = %{}
    {:ok, {accounts, refs}}
  end

  @impl true
  def handle_call({:withdaw, name, amount, currency}, _from, {accounts, _refs} = state) do
    case Map.fetch(accounts, name) do
      {:ok, pid} ->
        case Bucket.get(pid, currency) do
          nil ->
            {:reply, {:error, :not_enough_money}, state}

          balance when balance >= amount ->
            new_balance = Float.round(balance - amount, 2)
            Bucket.put(pid, currency, new_balance)
            {:reply, {:ok, new_balance}, state}

          _balance ->
            {:reply, {:error, :not_enough_money}, state}
        end

      _ ->
        {:reply, {:error, :user_does_not_exist}, state}
    end
  end

  @impl true
  def handle_call({:get_balance, name, currency}, _from, {accounts, _refs} = state) do
    case Map.fetch(accounts, name) do
      {:ok, pid} ->
        case Bucket.get(pid, currency) do
          nil ->
            {:reply, {:ok, 0.00}, state}

          balance ->
            {:reply, {:ok, balance}, state}
        end

      _ ->
        {:reply, {:error, :user_does_not_exist}, state}
    end
  end

  @impl true
  def handle_call({:deposit, name, amount, currency}, _from, {accounts, refs}) do
    # try find the user account
    case Map.fetch(accounts, name) do
      {:ok, pid} ->
        # find and update the balance in the specified currency for this user account
        balance =
          case Bucket.get(pid, currency) do
            nil -> Float.round(amount, 2)
            current_balance -> Float.round(current_balance + amount, 2)
          end

        # update user balance
        Bucket.put(pid, currency, balance)
        {:reply, {:ok, balance}, {accounts, refs}}

      :error ->
        {:reply, {:error, :user_does_not_exist}, {accounts, refs}}
    end
  end

  @impl true
  def handle_call({:create, name}, _from, {accounts, refs}) do
    if Map.has_key?(accounts, name) do
      {:reply, {:error, :user_already_exists}, {accounts, refs}}
    else
      {:ok, pid} = Bucket.start_link(%{})
      # monitor for process stop
      ref = Process.monitor(pid)
      # update references for monitor process
      refs = Map.put(refs, ref, name)
      accounts = Map.put(accounts, name, pid)
      {:reply, :ok, {accounts, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {accounts, refs}) do
    {name, refs} = Map.pop(refs, ref)
    accounts = Map.delete(accounts, name)
    {:noreply, {accounts, refs}}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
