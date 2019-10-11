defmodule HttpServer.Application do
  @moduledoc false
  use Application

  @routes [
    {"/ws", HttpServer.Websockets.Handler, []},
    {:_, Plug.Cowboy.Handler, {HttpServer.Router, []}}
  ]

  def start(_, _) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: HttpServer.Router,
        options: [
          dispatch: dispatch_table(),
          port: 4001
        ]
      )
    ]

    opts = [strategy: :one_for_one, name: HttpServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch_table, do: [{:_, @routes}]
end
