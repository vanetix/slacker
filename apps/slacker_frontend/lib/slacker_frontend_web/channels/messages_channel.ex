defmodule SlackerFrontendWeb.ChatChannel do
  use SlackerFrontendWeb, :channel

  alias SlackerBackend.Message

  def join("chat:lobby", _payload, socket) do
    send(self(), :on_join)

    {:ok, socket}
  end

  def handle_in("new-channel", channel_name, socket) do
    SlackerBackend.create(channel_name)

    broadcast!(socket, "new-channel", %{name: channel_name})

    {:noreply, socket}
  end

  def handle_in("delete-channel", channel_name, socket) do
    SlackerBackend.delete(channel_name)

    broadcast!(socket, "delete-channel", %{name: channel_name})

    {:noreply, socket}
  end

  def handle_in("join:" <> channel_name, _, socket) do
    messages = SlackerBackend.join(self(), channel_name)

    {:reply, {:ok, %{messages: messages}}, socket}
  end

  def handle_in("leave:" <> channel_name, _, socket) do
    SlackerBackend.leave(self(), channel_name)

    {:noreply, socket}
  end

  def handle_in("new-message:" <> channel_name, payload, socket) do
    Message.new(%{
      user: payload["user"],
      body: payload["body"]
    })
    |> SlackerBackend.new_message(channel_name)

    {:noreply, socket}
  end

  def handle_info(:on_join, socket) do
    push(socket, "sync", %{channels: SlackerBackend.list_channels()})

    {:noreply, socket}
  end

  def handle_info({:new_message, channel_name, message}, socket) do
    push(socket, "new-message:#{channel_name}", message)

    {:noreply, socket}
  end

  def handle_info({:new_channel, channel_name}, socket) do
    push(socket, "new-channel", channel_name)

    {:noreply, socket}
  end
end
