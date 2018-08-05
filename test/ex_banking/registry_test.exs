defmodule ExBanking.RegistryTest do
  use ExUnit.Case, async: false
  require IEx
  doctest ExBanking

  test "removes bucket on crash" do
    ExBanking.create_user("user12")
    pid = ExBanking.Registry.lookup(ExBanking.Registry, "user12")

    # Stop the bucket with non-normal reason
    Agent.stop(pid, :shutdown)

    # wait a sec for supervisor restart
    :timer.sleep(1_000)
    assert ExBanking.Registry.lookup(ExBanking.Registry, "user12") == :error
  end
end
