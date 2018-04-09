defmodule SlackerBackend.Channel do
  use GenServer

  alias SlackerBackend.Leader.Registry

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init([name]), do: init([name, []])
  def init([name, messages]) do
    Registry.register(self(), name)
    :pg2.create(pg_group(name))

    {:ok, %{name: name, messages: messages}}
  end

  defp pg_group(name), do: {:slacker_backend, "channel_#{name}"}

  def members(name) do
    name
    |> pg_group()
    |> :pg2.get_members()
  end

  def join(pid, member_pid) do
    GenServer.cast(pid, {:join, member_pid})
  end

  def leave(pid, member_pid) do
    GenServer.cast(pid, {:leave, member_pid})
  end

  def list_messages(pid) do
    GenServer.call(pid, :list_messages)
  end

  def new_message(pid, message) do
    GenServer.cast(pid, {:new_message, message})
  end

  def handle_call(:list_messages, _from, %{messages: messages} = state) do
    {:reply, Enum.reverse(messages), state}
  end

  # Magic crash word
  def handle_cast({:new_message, %{body: "fire"}}, %{name: name}), do: raise "Channel killed: #{name}."
  def handle_cast({:new_message, message}, %{messages: messages} = state) do
    pg_group(state.name)
    |> :pg2.get_members()
    |> Enum.each(fn(pid) ->
      send(pid, {:new_message, state.name, message})
    end)

    {:noreply, %{state | messages: [message | messages]}}
  end

  def handle_cast({:join, pid}, %{name: name} = state) do
    group = pg_group(name)
    members = :pg2.get_members(group)

    unless pid in members do
      :pg2.join(group, pid)
    end

    {:noreply, state}
  end

  def handle_cast({:leave, pid}, %{name: name} = state) do
    pg_group(name)
    |> :pg2.leave(pid)

    {:noreply, state}
  end
end
