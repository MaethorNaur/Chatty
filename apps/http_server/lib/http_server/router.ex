defmodule HttpServer.Router do
  use Plug.Router
  use Plug.ErrorHandler

  if Mix.env() == :dev do
    use Plug.Debugger
  end

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Helloworld")
  end
end
