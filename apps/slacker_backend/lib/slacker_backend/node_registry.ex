defmodule SlackerBackend.NodeRegistry do
  use GenServer

  @table __MODULE__
  @pg_group __MODULE__

  @doc """
  Return a list of maps contain name and active attributes
  """
  def list() do
    current = Node.self()

    :ets.foldl(fn({name}, acc) ->
      cur = %{
        name: name,
        active: name == current
      }

      [cur | acc]
    end, [], @table)
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

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :pg2.create(@pg_group)
    :net_kernel.monitor_nodes(true)
    :ets.new(@table, [:named_table, :protected])

    Enum.each([Node.self() | Node.list()], fn(name) ->
      :ets.insert(@table, {name})
    end)

    {:ok, %{}}
  end

  def handle_info({:nodeup, name}, state) do
    :ets.insert(@table, {name})

    update_subscribers()

    {:noreply, state}
  end

  def handle_info({:nodedown, name}, state) do
    :ets.delete(@table, name)

    update_subscribers()

    {:noreply, state}
  end

  defp update_subscribers() do
    nodes = list()

    @pg_group
    |> :pg2.get_members()
    |> Enum.each(fn(pid) ->
      send(pid, {:node_update, nodes})
    end)
  end
end
