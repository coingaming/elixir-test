defmodule ExBanking.Supervisor do
  @moduledoc """
  Supervisor module, allow fault tolerant 
  in case of fail guarantee that 
  the application continue working
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {ExBanking.Registry, name: ExBanking.Registry}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
