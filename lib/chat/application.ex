defmodule Chatty.Application do
  use Application

  def start(_, _) do
    children = [%{id: Chatty.Http.Suppervisor, start: {Chatty.Http.Suppervisor, :start_link, []}}]
    opts = [strategy: :one_for_one, name: Chatty.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
