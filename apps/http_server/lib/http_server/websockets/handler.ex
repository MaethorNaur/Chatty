defmodule HttpServer.Websockets.Handler do
  @moduledoc false
  alias HttpServer.Websockets.Message
  require Logger
  @behaviour :cowboy_websocket
  @timeout 60_000

  def init(req, state),
    do: :cowboy_req.match_qs([:user], req) |> get_username() |> init(req, state)

  @spec init({:ok, String.t()} | :error, any(), any()) :: any()
  def init({:ok, user}, req, _state),
    do: {:cowboy_websocket, req, user, %{:idle_timeout => @timeout}}

  def init(:error, _req, state), do: {:stop, state}
  def get_username(%{:user => user}) when user != "", do: {:ok, user}
  def get_username(_), do: :error

  defp join(user) do
    :pg2.create({:ws, user})
    :pg2.join({:ws, user}, self())
  end

  defp quit(user), do: {:ws, user} |> :pg2.get_members() |> delete(user)
  defp delete([], user), do: :pg2.delete({:ws, user})
  defp delete({:error, {:no_such_group, _}}, _user), do: :error
  defp delete(_pids, _user), do: :ok

  def websocket_init(state) do
    join(state)
    Logger.info("connected", user: state)
    {:ok, state, :hibernate}
  end

  def websocket_handle({:ping, message}, state), do: {:reply, {:pong, message}, state, :hibernate}
  def websocket_handle(:ping, state), do: {:reply, :pong, state, :hibernate}

  def websocket_handle({:text, raw_message}, state) do
    resp =
      case Message.parse(raw_message) do
        {:ok, %Message{to: to, message: message}} -> "@#{state} > #{to} #{message}"
        {:error, error} -> ">#{error}"
      end

    {:reply, {:text, resp}, state, :hibernate}
  end

  def websocket_info(message, state), do: {:reply, {:text, message}, state, :hibernate}

  def terminate(_reason, _req, state) do
    Logger.info("disconnected", user: state)

    case quit(state) do
      :ok ->
        Logger.info("group destroy", user: state)

      :error ->
        Logger.error("No deleted", user: state)
    end

    :ok
  end
end
