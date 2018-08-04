defmodule ExBanking.Registry do
  use GenServer
  alias ExBanking.Bucket

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

  ## Server Callbacks

  @impl true
  def init(_) do
    refs = %{}
    accounts = %{}
    {:ok, {accounts, refs}}
  end

  @impl true
  def handle_call({:create, name}, _from, {accounts, refs}) do
    if Map.has_key?(accounts, name) do
      {:reply, :user_already_exists, {accounts, refs}}
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

  @doc """
  Mantain registry up to date, when a bucket (Agent) stop for any reason
  should be also deleted from the registry
  """
  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {accounts, refs}) do
    {name, refs} = Map.pop(refs, ref)
    accounts = Map.delete(accounts, name)
    {:noreply, {accounts, refs}}
  end

  @doc """
  Any other message received do nothing
  """
  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
