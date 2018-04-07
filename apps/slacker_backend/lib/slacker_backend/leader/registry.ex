defmodule SlackerBackend.Leader.Registry do
  @moduledoc """
  Manages pids of all existing channels on the local node.
  """

  use GenServer

  alias SlackerBackend.NodeRegistry

  @table __MODULE__
  @subscription_table :channel_subscriptions

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {results, _} = :rpc.multicall(Node.list(), __MODULE__, :list_with_pid, [])

    results
    |> List.flatten()
    |> Enum.each(fn({name, pid}) ->
      GenServer.cast(__MODULE__, {:register, pid, name})
    end)

    :ets.new(@table, [:protected, :named_table])
    :ets.new(@subscription_table, [:named_table])

    {:ok, %{}}
  end

  def subscribe(pid) do
    GenServer.cast(__MODULE__, {:subscribe, pid})
  end

  def unsubscribe(pid) do
    GenServer.cast(__MODULE__, {:unsubscribe, pid})
  end

  def register(pid, name) when is_pid(pid) and is_binary(name) do
    for %{name: node_name} <- NodeRegistry.list() do
      GenServer.cast({__MODULE__, node_name}, {:register, pid, name})
    end
  end

  def pid_for_name(name) when is_binary(name) do
    case :ets.lookup(@table, name) do
      [{^name, pid}] ->
        {:ok, pid}
      [] ->
        {:error, :not_found}
    end
  end

  def list() do
    :ets.foldl(fn({name, _}, acc) ->
      [name | acc]
    end, [], @table)
    |> Enum.sort()
  end

  def list_with_pid() do
    :ets.foldl(&([&1 | &2]), [], @table)
  end

  def handle_cast({:register, pid, name}, state) do
    ref = Process.monitor(pid)

    :ets.insert(@table, {name, pid})

    for pid <- get_subscribers() do
      send(pid, {:new_channel, name})
    end

    {:noreply, Map.put(state, ref, name)}
  end
  def handle_cast({:subscribe, pid}, state) do
    :ets.insert(@subscription_table, {pid})

    {:noreply, state}
  end
  def handle_cast({:unsubscribe, pid}, state) do
    :ets.delete(@subscription_table, {pid})

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {name, new_state} = Map.pop(state, ref)

    :ets.delete(@table, name)

    for pid <- get_subscribers() do
      send(pid, {:delete_channel, name})
    end

    {:noreply, new_state}
  end

  defp get_subscribers() do
    :ets.foldl(fn({pid}, acc) ->
      [pid | acc]
    end, [], @subscription_table)
  end
end
