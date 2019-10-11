defmodule Chatty.Http.Suppervisor do
  use Elixir.Supervisor

  @routes [
    {"/ws", Chatty.Http.Websockets.Handler, []},
    {:_, Plug.Cowboy.Handler, {Chatty.Http.Router, []}}
  ]
  def start_link(), do: Elixir.Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Chatty.Http.Router,
        options: [
          dispatch: dispatch_table(),
          port: 4001
        ]
      )
    ]

    Elixir.Supervisor.init(children, strategy: :one_for_one)
  end

  defp dispatch_table, do: [{:_, @routes}]
end
