defmodule ExBanking.Registry do
  use GenServer
  alias ExBanking.Bucket
  require IEx

  ## Client API
  @tab :counter_requests
  @max_requests 10

  @doc """
  Starts the registry with te given options

  `name` is always required
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @doc """
  Retreive bucket by name
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
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
    case limiter_requests(name, 1) do
      :ok ->
        reply = GenServer.call(server, {:deposit, name, amount, currency})
        limiter_requests(name, -1)
        reply

      reply ->
        limiter_requests(name, -1)
        reply
    end
  end

  @doc """
  Get the balance for the user and currency specified
  """
  def get_balance(server, name, currency) do
    case limiter_requests(name, 1) do
      :ok ->
        reply = GenServer.call(server, {:get_balance, name, currency})
        limiter_requests(name, -1)
        reply

      reply ->
        limiter_requests(name, -1)
        reply
    end
  end

  @doc """
  Withdraw the specified amount from the user balance in the specified currency
  """
  def withdraw(server, name, amount, currency) do
    case limiter_requests(name, 1) do
      :ok ->
        reply = GenServer.call(server, {:withdraw, name, amount, currency})
        limiter_requests(name, -1)
        reply

      reply ->
        limiter_requests(name, -1)
        reply
    end
  end

  @doc """
  Transfer money between users
  """
  def send(server, from, to, amount, currency) do
    case limiter_requests(from, 1) do
      :ok ->
        case limiter_requests(to, 1) do
          :ok ->
            reply = GenServer.call(server, {:send, from, to, amount, currency}, :infinity)
            limiter_requests(to, -1)
            limiter_requests(from, -1)
            reply

          _reply ->
            limiter_requests(to, -1)
            limiter_requests(from, -1)
            {:error, :too_many_requests_to_receiver}
        end

      _reply ->
        limiter_requests(from, -1)
        {:error, :too_many_requests_to_sender}
    end
  end

  @doc """
  Limit quantity of requests per moment
  """
  def limiter_requests(user, incr) do
    case :ets.update_counter(@tab, user, {2, incr}, {user, 0}) do
      count when count > @max_requests -> {:error, :too_many_requests_to_user}
      _count -> :ok
    end
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    :ets.new(@tab, [:set, :named_table, :public, read_concurrency: true, write_concurrency: true])
    refs = %{}
    accounts = %{}
    {:ok, {accounts, refs}}
  end

  @impl true
  def handle_call({:send, from, to, amount, currency}, _from, {accounts, _refs} = state) do
    case Map.fetch(accounts, from) do
      {:ok, pid_from} ->
        case Bucket.get(pid_from, currency) do
          nil ->
            {:reply, {:error, :not_enough_money}, state}

          balance when balance >= amount ->
            case Map.fetch(accounts, to) do
              {:ok, pid_to} ->
                new_balance_to =
                  case Bucket.get(pid_to, currency) do
                    nil -> Float.round(amount, 2)
                    balance -> Float.round(balance + amount, 2)
                  end

                Bucket.put(pid_to, currency, new_balance_to)
                new_balance_from = Float.round(balance - amount, 2)
                Bucket.put(pid_from, currency, new_balance_from)
                {:reply, {:ok, new_balance_from, new_balance_to}, state}

              _ ->
                {:reply, {:error, :receiver_does_not_exist}, state}
            end

          _balance ->
            {:reply, {:error, :not_enough_money}, state}
        end

      _ ->
        {:reply, {:error, :sender_does_not_exist}, state}
    end
  end

  @impl true
  def handle_call({:withdraw, name, amount, currency}, _from, {accounts, _refs} = state) do
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
  def handle_call({:lookup, name}, _from, {accounts, _refs} = state) do
    case Map.fetch(accounts, name) do
      {:ok, pid} ->
        {:reply, pid, state}

      :error ->
        {:reply, :error, state}
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
