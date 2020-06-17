defmodule Chatty.Application do
  @moduledoc false
  use Application

  @routes [
    {"/ws", Chatty.Websockets.Handler, []},
    {:_, Plug.Cowboy.Handler, {Chatty.Router, []}}
  ]

  def start(_, _) do
    topology = Application.get_env(:libcluster, :topologies)
    hosts = topology[:chatty][:config][:hosts]
    idx = hosts |> Enum.find_index(&(&1 == Node.self())) |> rem(2)

    children = [
      {Cluster.Supervisor, [topology, [name: Chatty.ClusterSupervisor]]},
      %{id: Chatty.NodeMonitor, start: {Chatty.NodeMonitor, :start_link, []}},
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Chatty.Router,
        options: [
          dispatch: dispatch_table(),
          port: 4001 + idx
        ]
      )
    ]

    opts = [strategy: :one_for_one, name: Chatty.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch_table, do: [{:_, @routes}]
end
