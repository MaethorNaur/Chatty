defmodule Chatty.NodeMonitor do
  @moduledoc false
  use GenServer
  alias Chatty.Websockets.Handler
  def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok) do
    _ = :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, nil}
  end

  @impl true
  def handle_info({:nodedown, _node, [node_type: :visible]}, state) do
    Handler.all() |> :pg2.get_members() |> Enum.each(&send(&1, :list_rooms_with_users))
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}
end
