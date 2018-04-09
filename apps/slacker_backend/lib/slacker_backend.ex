defmodule SlackerBackend do
  @moduledoc """
  Handles all functionality to interact with the Slacker backend service.
  """

  alias SlackerBackend.{Channel, Message, NodeRegistry}
  alias SlackerBackend.Leader.Registry
  alias SlackerBackend.Leader.Supervisor, as: ChannelSupervisor

  defdelegate subscribe_to_node_updates(pid), to: NodeRegistry, as: :subscribe
  defdelegate unsubscribe_to_node_updates(pid), to: NodeRegistry, as: :unsubscribe
  defdelegate subscribe_to_channel_updates(pid), to: Registry, as: :subscribe
  defdelegate unsubscribe_to_channel_updates(pid), to: Registry, as: :unsubscribe

  def list_channels() do
    Registry.list()
  end

  def list_nodes() do
    NodeRegistry.list()
  end

  @doc """
  Join a pid to a channel, and return message history
  """
  def join(pid, name) when is_pid(pid) and is_binary(name) do
    case Registry.pid_for_name(name) do
      {:ok, channel_pid} ->
        Channel.join(channel_pid, pid)

        Channel.list_messages(channel_pid)
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Remove a pid from a channel
  """
  def leave(pid, name) when is_pid(pid) and is_binary(name) do
    case Registry.pid_for_name(name) do
      {:ok, channel_pid} ->
        Channel.leave(channel_pid, pid)
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Create a new channel with `name`
  """
  def create(name) when is_binary(name) do
    case Registry.pid_for_name(name) do
      {:ok, _pid} ->
        {:error, :channel_exists}
      {:error, _reason} ->
        DynamicSupervisor.start_child(ChannelSupervisor, {Channel, [name]})
    end
  end

  @doc """
  Delete the channel with `name`
  """
  def delete(name) when is_binary(name) do
    case Registry.pid_for_name(name) do
      {:ok, channel_pid} ->
        DynamicSupervisor.terminate_child(ChannelSupervisor, channel_pid)
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Send a new message to the channel
  """
  def new_message(message = %Message{}, name) when is_binary(name) do
    case Registry.pid_for_name(name) do
      {:ok, pid} ->
        Channel.new_message(pid, message)
      {:error, reason} ->
        {:error, reason}
    end
  end

  def do_handoff(name, messages) do
    DynamicSupervisor.start_child(ChannelSupervisor, {Channel, [name, messages]})
  end

  @doc """
  Drain off the local channel supervisor to other cluster nodes
  """
  def drain() do
    case Node.list() do
      [] ->
        {:error, :no_connected_nodes}
      nodes ->
        do_drain(nodes)
    end
  end

  defp do_drain(nodes) do
    ChannelSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.map(fn({_, pid, _, _}) ->
      new_node = Enum.random(nodes)
      messages = Channel.list_messages(pid)
      {:ok, name} = Registry.name_for_pid(pid)

      DynamicSupervisor.terminate_child(ChannelSupervisor, pid)
      :rpc.async_call(new_node, SlackerBackend, :do_handoff, [name, messages])
    end)
    |> Enum.map(&(:rpc.yield(&1)))
  end
end
