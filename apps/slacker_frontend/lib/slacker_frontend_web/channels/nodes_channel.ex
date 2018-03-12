defmodule SlackerFrontendWeb.NodesChannel do
  use SlackerFrontendWeb, :channel

  def join("nodes:lobby", _payload, socket) do
    send(self(), :on_join)
    SlackerBackend.subscribe_to_node_updates(self())

    {:ok, socket}
  end

  def handle_info(:on_join, socket) do
    push(socket, "nodes", %{nodes: SlackerBackend.list_nodes()})

    {:noreply, socket}
  end

  def handle_info({:node_update, nodes}, socket) do
    push(socket, "nodes", %{nodes: nodes})

    {:noreply, socket}
  end
end
