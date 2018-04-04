defmodule SlackerBackend.Leader.Registry do
  use GenServer

  alias SlackerBackend.NodeRegistry

  @table __MODULE__
  @pg_group __MODULE__

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

    :pg2.create(@pg_group)
    :ets.new(@table, [:protected, :named_table])

    {:ok, %{channels: %{}}}
  end

  def subscribe(pid) do
    unless pid in :pg2.get_members(@pg_group) do
      :pg2.join(@pg_group, pid)
    end
  end

  def unsubscribe(pid) do
    if pid in :pg2.get_members(@pg_group) do
      :pg2.leave(@pg_group, pid)
    end
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

    @pg_group
    |> :pg2.get_members()
    |> Enum.each(fn(pid) ->
      send(pid, {:new_channel, name})
    end)

    {:noreply, Map.put(state, ref, name)}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {name, new_state} = Map.pop(state, ref)

    :ets.delete(@table, name)

    @pg_group
    |> :pg2.get_members()
    |> Enum.each(fn(pid) ->
      send(pid, {:delete_channel, name})
    end)

    {:noreply, new_state}
  end
end
